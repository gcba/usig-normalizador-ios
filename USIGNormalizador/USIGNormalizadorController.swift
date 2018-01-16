//
//  USIGViewController.swift
//  USIGNormalizadorController
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//
//  Icons by SimpleIcon https://creativecommons.org/licenses/by/3.0/
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Moya
import DZNEmptyDataSet

fileprivate enum SearchState {
    case notFound
    case empty
    case error
}

public class USIGNormalizadorController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!

    // MARK: - Properties

    public var delegate: USIGNormalizadorControllerDelegate?
    public var edit: String?
    
    fileprivate var value: USIGNormalizadorAddress?
    fileprivate var normalizationAPIProvider: RxMoyaProvider<USIGNormalizadorAPI>!
    fileprivate var epokAPIProvider: RxMoyaProvider<USIGEpokAPI>!
    fileprivate var onDismissCallback: ((UIViewController) -> Void)?
    fileprivate var searchController: UISearchController!
    
    fileprivate var actions: [USIGNormalizadorAction] = []
    fileprivate var results: [USIGNormalizadorAddress] = []
    fileprivate var actionsSection: Int = 0
    fileprivate var contentSection: Int = 1
    fileprivate var state: SearchState = .empty
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate let whitespace: CharacterSet = .whitespacesAndNewlines
    fileprivate let minCharactersNormalization: Int = 3
    fileprivate let minCharactersEpok: Int = 4
    
    fileprivate var visibleActions: [USIGNormalizadorAction] {
        return actions.filter { action in action.visible.value }
    }

    fileprivate var showPin: Bool {
        return delegate?.shouldShowPin(self) ?? USIGNormalizadorConfig.shouldShowPinDefault
    }

    fileprivate var forceNormalization: Bool {
        return delegate?.shouldForceNormalization(self) ?? USIGNormalizadorConfig.shouldForceNormalizationDefault
    }
    
    fileprivate var includePlaces: Bool {
        return delegate?.shouldIncludePlaces(self) ?? USIGNormalizadorConfig.shouldIncludePlacesDefault
    }
    
    fileprivate var showSuffix: Bool {
        return delegate?.shouldShowSuffix(self) ?? USIGNormalizadorConfig.shouldShowSuffixDefault
    }
    
    fileprivate var exclusions: String {
        return delegate?.exclude(self) ?? USIGNormalizadorConfig.exclusionsDefault
    }
    
    fileprivate var maxResults: Int {
        return delegate != nil && delegate!.maxResults(self) > 0 ? delegate!.maxResults(self) : USIGNormalizadorConfig.maxResultsDefault
    }

    fileprivate var pinImage: UIImage! {
        return delegate?.pinImage(self) ?? USIGNormalizadorConfig.pinImageDefault
    }
    
    fileprivate var pinColor: UIColor {
        return delegate?.pinColor(self) ?? USIGNormalizadorConfig.pinColorDefault
    }

    fileprivate var pinText: String {
        return delegate?.pinText(self) ?? USIGNormalizadorConfig.pinTextDefault
    }
    
    fileprivate var addressImage: UIImage! {
        return delegate?.addressImage(self) ?? USIGNormalizadorConfig.addressImageDefault
    }
    
    fileprivate var addressColor: UIColor {
        return delegate?.addressColor(self) ?? USIGNormalizadorConfig.addressColorDefault
    }
    
    fileprivate var placeImage: UIImage! {
        return delegate?.placeImage(self) ?? USIGNormalizadorConfig.placeImageDefault
    }
    
    fileprivate var placeColor: UIColor {
        return delegate?.placeColor(self) ?? USIGNormalizadorConfig.placeColorDefault
    }

    // MARK: - Overrides

    override public func viewDidLoad() {
        super.viewDidLoad()

        checkDelegate()
        setupNavigationBar()
        setupTableView()
        setupAPIProviders()
        setupActions()
        setInitialValue()
        setupRx()
        setupKeyboardNotifications()

        definesPresentationContext = true
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        searchController.isActive = true
    }

    // MARK: - Setup methods

    private func setupNavigationBar() {
        searchController = UISearchController(searchResultsController:  nil)

        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        
        if value != nil {
            searchController.searchBar.text = showSuffix ? value!.address : value!.address.removeSuffix(from: value!)
        }

        navigationController?.navigationBar.isTranslucent = false
        navigationItem.titleView = searchController.searchBar
        navigationItem.hidesBackButton = true
    }

    private func setupTableView() {
        table.dataSource = self
        table.delegate = self
        table.alwaysBounceVertical = false
        table.tableFooterView = UIView(frame: .zero)
        table.emptyDataSetSource = self
        table.emptyDataSetDelegate = self
        table.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        table.register(USIGNormalizadorCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func setupAPIProviders() {
        let requestClosure = { (request: URLRequest, done: RxMoyaProvider.RequestResultClosure) in
            var mutableRequest = request
            
            mutableRequest.cachePolicy = .returnCacheDataElseLoad
            
            done(.success(mutableRequest))
        }
        
        normalizationAPIProvider = RxMoyaProvider<USIGNormalizadorAPI>(requestClosure: { (endpoint: Endpoint<USIGNormalizadorAPI>, done: RxMoyaProvider.RequestResultClosure) in
            requestClosure(endpoint.urlRequest!, done)
        })
        
        epokAPIProvider = RxMoyaProvider<USIGEpokAPI>(requestClosure: { (endpoint: Endpoint<USIGEpokAPI>, done: RxMoyaProvider.RequestResultClosure) in
            requestClosure(endpoint.urlRequest!, done)
        })
    }

    private func setupRx() {
        let normalizationConfig = NormalizadorProviderConfig(excluyendo: exclusions, geocodificar: true, max: maxResults, minCharacters: minCharactersNormalization)
        let normalizationAddressProvider = NormalizadorProvider(with: normalizationConfig, api: normalizationAPIProvider)
        
        let searchStream = searchController.searchBar.rx
            .text
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged(filterSearch)
            .filter(filterSearch)
            .flatMapLatest { query in Observable.from(optional: query) }
            .shareReplayLatestWhileConnected()
            .do(onNext: { _ in
                DispatchQueue.main.async { [unowned self] in
                    if !self.searchController.searchBar.isLoading {
                        self.searchController.searchBar.isLoading = true
                    }
                }
            })
        
        let normalizationStream = normalizationAddressProvider.getStream(from: searchStream)
        var sources: [Observable<[USIGNormalizadorResponse]>] = [normalizationStream]
        
        if includePlaces {
            let epokConfig = EpokProviderConfig(
                categoria: nil,
                clase: nil,
                boundingBox: nil,
                start: nil,
                limit: maxResults,
                total: false,
                minCharacters: minCharactersEpok,
                normalization: normalizationConfig
            )
            
            let epokAddressProvider = EpokProvider(with: epokConfig, apiProvider: epokAPIProvider, normalizationAPIProvider: normalizationAPIProvider)
            let epokStream = epokAddressProvider.getStream(from: searchStream)
            
            sources.append(epokStream)
        }
        
        for action in actions {
            action.visible
                .asObservable()
                .subscribe(onNext: {[unowned self] _ in self.table.reloadSections(IndexSet(integer: self.actionsSection), with: .none) })
                .addDisposableTo(disposeBag)
        }

        table.rx
            .itemSelected
            .subscribe(onNext: handleSelectedItem)
            .addDisposableTo(disposeBag)
        
        AddressManager()
            .getStreams(from: sources)
            .observeOn(ConcurrentMainScheduler.instance)
            .subscribe(onNext: handleResults)
            .addDisposableTo(disposeBag)
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    private func setupActions() {
        let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

        let pinCell = ActionCell(text: NSAttributedString(string: pinText, attributes: attributes), detailText: nil, icon: pinImage, iconTint: pinColor)
        let pinAction = PinAction(cell: pinCell, visible: showPin)
        let noNormalizationCell = ActionCell()
        let noNormalizationAction = NoNormalizationAction(cell: noNormalizationCell, visible: false) // Hide it at first because it's empty
        
        actions.append(pinAction)
        actions.append(noNormalizationAction)
    }

    private func setInitialValue() {
        if let initialValue = edit, initialValue.trimmingCharacters(in: whitespace).characters.count > 0 {
            searchController.searchBar.textField?.rx.value.onNext(initialValue.components(separatedBy: ",").dropLast().joined(separator: ","))
        }
    }
    
    // MARK: - Notifications
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo: NSDictionary = (notification as NSNotification).userInfo as NSDictionary?,
            let keyboardFrame: NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as? NSValue else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.tableBottomConstraint.constant = keyboardFrame.cgRectValue.height
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.tableBottomConstraint.constant = 0
        }
    }

    // MARK: - Helper methods

    private func checkDelegate() {
        if delegate == nil {
            fatalError("USIGNormalizadorController delegate is not implemented.")
        }
    }
    
    private func filterSearch(_ previousQuery: String?, _ nextQuery: String?) -> Bool {
        if let previous = previousQuery, let next = nextQuery {
            return previous.trimmingCharacters(in: .whitespacesAndNewlines) == next.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return false
    }

    private func filterSearch(_ value: String?) -> Bool {
        if let text = value, text.trimmingCharacters(in: whitespace).characters.count >= minCharactersNormalization { return true }
        else  {
            let actionIndex = actions.index(where: { action in action is NoNormalizationAction })
            
            actions[actionIndex!].cell.text = NSAttributedString(string: "")
            searchController.searchBar.textField?.text = searchController.searchBar.textField?.text?.trimmingCharacters(in: whitespace)
            state = .empty
            results = []
            
            reloadTable()
            
            return false
        }
    }
    
    private func handleResults(_ results: [USIGNormalizadorResponse]) {
        let filteredResults = results.filter({ response in response.error == nil && response.addresses != nil && response.addresses!.count > 0 })
        
        self.results = []
        
        DispatchQueue.main.async { [unowned self] in
            if self.searchController.searchBar.isLoading {
                self.searchController.searchBar.isLoading = false
            }
        }
        
        if filteredResults.count == 0 {
            for result in results {
                if let error = result.error {
                    switch error {
                    case .streetNotFound(_):
                        self.state = .notFound
                            
                        reloadTable()
                            
                        return
                    case .service(let message):
                        debugPrint("ERROR: \(message)")
                        
                        self.state = .error
                            
                        reloadTable()
                            
                        return
                    case .other(let message):
                        debugPrint("ERROR: \(message)")
                        
                        self.state = .error
                            
                        reloadTable()
                            
                        return
                    default: break
                    }
                }
            }
        }
        
        
        self.results = Array(filteredResults.flatMap({ response in response.addresses! }).prefix(maxResults))
        
        reloadTable(sections: [contentSection])
    }

    private func handleSelectedItem(indexPath: IndexPath) {
        if indexPath.section == contentSection {
            let result = self.results[indexPath.row]

            guard (result.number != nil && result.type == "calle_altura") || result.type == "calle_y_calle" else {
                DispatchQueue.main.async { [unowned self] in
                    self.results = []

                    self.results.append(result)
                    self.reloadTable(sections: [self.contentSection])

                    if !self.forceNormalization {
                        self.reloadTable(sections: [self.actionsSection])
                    }

                    self.searchController.searchBar.textField?.text = result.street + " "
                }

                return
            }

            value = result

            delegate?.didSelectValue(self, value: result)
        } else {
            let action = visibleActions[indexPath.row]
            
            if action is PinAction {
                delegate?.didSelectPin(self)
            }
            else if action is NoNormalizationAction {
                delegate?.didSelectUnnormalizedAddress(self, value: action.cell.text.string)
            }
        }

        close(force: true)
    }
    
    private func reloadTable(sections: [Int]? = nil) {
        DispatchQueue.main.async { [unowned self] in
            if let indexes = sections {
                self.table.reloadSections(IndexSet(indexes), with: .none)
            }
            else {
                self.table.reloadSections(IndexSet(integersIn: 0..<self.table.numberOfSections), with: .none)
            }
            
            self.table.reloadEmptyDataSet()
            
            if !self.forceNormalization,
                let actionIndex = self.actions.index(where: { action in action is NoNormalizationAction }),
                let text = self.searchController.searchBar.textField?.text?.trimmingCharacters(in: self.whitespace) {
                let equalItem = self.results.first { [unowned self] item in
                    self.showSuffix ? item.address == text.uppercased() : item.address.removeSuffix(from: item) == text.uppercased()
                }
                
                let isEqual = equalItem != nil
                let isShort = text.characters.count < self.minCharactersNormalization
                
                if !isShort {
                    self.actions[actionIndex].cell.text = NSAttributedString(string: text, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)])
                }
                
                self.actions[actionIndex].visible.value = !isEqual && !isShort
            }
        }
    }

    func close(force: Bool = false) {
        if navigationController?.viewControllers[0] === self {
            self.searchController.dismiss(animated: true) {
                if force {
                    self.dismiss(animated: true) {
                        self.onDismissCallback?(self)
                    }
                }
                else {
                    self.onDismissCallback?(self)
                }
            }
        }
        else if searchController.isFirstResponder {
            searchController.dismiss(animated: true) { [unowned self] in
                self.onDismissCallback?(self)
            }
        }
        else {
            onDismissCallback?(self)
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - Extensions

extension USIGNormalizadorController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return section == contentSection ? results.count : visibleActions.count }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if indexPath.section == contentSection {
            let result = results[indexPath.row]
            let address = showSuffix ? result.address : result.address.removeSuffix(from: result)
            
            if let label = result.label {
                cell.textLabel?.attributedText = label.highlight(searchController.searchBar.textField?.text)
                cell.detailTextLabel?.attributedText = address.highlight(searchController.searchBar.textField?.text, fontSize: 12)
            } else {
                cell.textLabel?.attributedText = address.highlight(searchController.searchBar.textField?.text)
                cell.detailTextLabel?.attributedText = nil
            }
            
            switch result.source {
            case is USIGNormalizadorAPI.Type:
                cell.imageView?.image = addressImage.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = addressColor
            case is USIGEpokAPI.Type:
                cell.imageView?.image = placeImage.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = placeColor
            default:
                break
            }
        }
        else {
            let action = visibleActions[indexPath.row]
            
            cell.imageView?.image = action.cell.icon?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = action.cell.iconTint
            cell.textLabel?.attributedText = action.cell.text
            cell.detailTextLabel?.attributedText = action.cell.detailText
        }
        
        return cell
    }
}

extension USIGNormalizadorController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) { }

    public func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        delegate?.didCancelSelection(self)
        close()
    }
}

extension USIGNormalizadorController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    public func emptyDataSetShouldBeForced(toDisplay scrollView: UIScrollView!) -> Bool {
        return results.count == 0
    }

    public func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let title: String
        let attributes = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]

        switch state {
        case .empty:
            title = ""
        case .notFound:
            title = "No Encontrado"
        case .error:
            title = "Error"
        }

        return NSAttributedString(string: title, attributes: attributes)
    }

    public func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let description: String
        let attributes = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]

        switch state {
        case .empty:
            description = ""
        case .notFound:
            description = "La búsqueda no tuvo resultados."
        case .error:
            description = "Asegurate de estar conectado a Internet."
        }

        return NSAttributedString(string: description, attributes: attributes)
    }

    public func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        let table = scrollView as! UITableView
        let tableHeight = table.tableFooterView!.frame.size.height
        let actionsSectionHeight = table.contentSize.height
        
        return CGFloat(tableHeight + actionsSectionHeight) / 2
    }
}

private extension String {
    func highlight(range boldRange: NSRange, fontSize: CGFloat = UIFont.systemFontSize) -> NSAttributedString {
        let bold = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: fontSize)]
        let nonBold = [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)]
        let attributedString = NSMutableAttributedString(string: self, attributes: nonBold)

        attributedString.setAttributes(bold, range: boldRange)

        return attributedString
    }

    func highlight(_ text: String?, fontSize: CGFloat = UIFont.systemFontSize) -> NSAttributedString {
        let haystack = self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let substring = text, let range = haystack.range(of: substring.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else {
            return highlight(range: NSRange(location: 0, length: 0))
        }

        let needle = substring.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lower16 = range.lowerBound.samePosition(in: haystack.utf16)
        let start = haystack.utf16.distance(from: haystack.utf16.startIndex, to: lower16)

        return highlight(range: NSRange(location: start, length: needle.characters.count), fontSize: fontSize)
    }
    
    func removeSuffix(from address: USIGNormalizadorAddress) -> String {
        return address.address.replacingOccurrences(of: ", \(address.districtName ?? "")", with: "").replacingOccurrences(of: ", \(address.localityName ?? "")", with: "")
    }
}

fileprivate extension UISearchBar {
    // From: https://stackoverflow.com/questions/37692809/uisearchcontroller-with-loading-indicator
    fileprivate var textField: UITextField? {
        return subviews.first?.subviews.flatMap { view in view as? UITextField }.first
    }

    // From: https://stackoverflow.com/questions/37692809/uisearchcontroller-with-loading-indicator
    fileprivate var activityIndicator: UIActivityIndicatorView? {
        return textField?.leftView?.subviews.flatMap { view in view as? UIActivityIndicatorView }.first
    }

    // From: https://stackoverflow.com/questions/37692809/uisearchcontroller-with-loading-indicator
    fileprivate var isLoading: Bool {
        get {
            return activityIndicator != nil
        }

        set {
            if newValue {
                if activityIndicator == nil {
                    let newActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

                    newActivityIndicator.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    newActivityIndicator.startAnimating()
                    newActivityIndicator.backgroundColor = UIColor.white
                    textField?.leftView?.addSubview(newActivityIndicator)

                    let leftViewSize = textField?.leftView?.frame.size ?? CGSize.zero

                    newActivityIndicator.center = CGPoint(x: leftViewSize.width / 2, y: leftViewSize.height / 2)
                }
            } else {
                activityIndicator?.removeFromSuperview()
            }
        }
    }
}
