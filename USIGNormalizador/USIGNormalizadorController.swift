//
//  USIGViewController.swift
//  USIGNormalizadorController
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
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

    fileprivate var exclusions: String {
        return delegate?.exclude(self) ?? USIGNormalizadorConfig.exclusionsDefault
    }

    fileprivate var maxResults: Int {
        return delegate != nil && delegate!.maxResults(self) > 0 ? delegate!.maxResults(self) : USIGNormalizadorConfig.maxResultsDefault
    }

    fileprivate var showPin: Bool {
        return delegate?.shouldShowPin(self) ?? USIGNormalizadorConfig.shouldShowPinDefault
    }

    fileprivate var forceNormalization: Bool {
        return delegate?.shouldForceNormalization(self) ?? USIGNormalizadorConfig.shouldForceNormalizationDefault
    }

    fileprivate var pinColor: UIColor {
        return delegate?.pinColor(self) ?? USIGNormalizadorConfig.pinColorDefault
    }

    fileprivate var pinImage: UIImage! {
        return delegate?.pinImage(self) ?? USIGNormalizadorConfig.pinImageDefault?.withRenderingMode(.alwaysTemplate)
    }

    fileprivate var pinText: String {
        return delegate?.pinText(self) ?? USIGNormalizadorConfig.pinTextDefault
    }

    fileprivate var rowsInFirstSection: Int {
        let pinCell = showPin ? 1 : 0
        let normalizationCell = !forceNormalization && !hideForceNormalizationCell &&
            searchController.searchBar.textField?.text != nil && searchController.searchBar.textField!.text!.trimmingCharacters(in: whitespace).characters.count > 0 ? 1 : 0

        return pinCell + normalizationCell
    }

    fileprivate var value: USIGNormalizadorAddress?
    fileprivate var provider: RxMoyaProvider<USIGNormalizadorAPI>!
    fileprivate var onDismissCallback: ((UIViewController) -> Void)?
    fileprivate var searchController: UISearchController!
    
    fileprivate var results: [USIGNormalizadorAddress] = []
    fileprivate var state: SearchState = .empty
    fileprivate var hideForceNormalizationCell: Bool = true
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate let whitespace: CharacterSet = .whitespacesAndNewlines
    fileprivate let addressSufix: String = ", CABA"

    // MARK: - Overrides

    override public func viewDidLoad() {
        super.viewDidLoad()

        checkDelegate()
        setupNavigationBar()
        setupTableView()
        setupRx()
        setInitialValue()
        setKeyboardNotifications()

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
        searchController.searchBar.text = value?.address.replacingOccurrences(of: addressSufix, with: "")

        navigationController?.navigationBar.isTranslucent = false
        navigationItem.titleView = searchController.searchBar
    }

    private func setupTableView() {
        table.dataSource = self
        table.delegate = self
        table.alwaysBounceVertical = false
        table.tableFooterView = UIView(frame: .zero)
        table.emptyDataSetSource = self
        table.emptyDataSetDelegate = self

        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    private func setupRx() {
        let requestClosure = { (endpoint: Endpoint<USIGNormalizadorAPI>, done: RxMoyaProvider.RequestResultClosure) in
            var request: URLRequest = endpoint.urlRequest!

            request.cachePolicy = .returnCacheDataElseLoad

            done(.success(request))
        }

        provider = RxMoyaProvider<USIGNormalizadorAPI>(requestClosure: requestClosure)

        searchController.searchBar
            .rx.text
            .debounce(0.5, scheduler: MainScheduler.instance)
            .filter(filterSearch)
            .flatMapLatest(makeRequest)
            .subscribe(onNext: handleResults, onError: handleError)
            .addDisposableTo(disposeBag)

        _ = table
            .rx.itemSelected
            .subscribe(onNext: handleSelectedItem)
    }

    private func setInitialValue() {
        if let initialValue = edit, initialValue.trimmingCharacters(in: whitespace).characters.count > 0 {
            searchController.searchBar.textField?.text = initialValue.replacingOccurrences(of: addressSufix, with: "")
        }
    }
    
    private func setKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    // MARK: - Helper methods

    private func checkDelegate() {
        if delegate == nil {
            fatalError("USIGNormalizadorController delegate is not implemented.")
        }
    }

    private func filterSearch(_ value: String?) -> Bool {
        if let text = value, text.trimmingCharacters(in: whitespace).characters.count > 2 { return true }
        else  {
            searchController.searchBar.textField?.text = searchController.searchBar.textField?.text?.trimmingCharacters(in: whitespace)
            state = .empty
            results = []
            hideForceNormalizationCell = true

            reloadTable()

            return false
        }
    }

    private func makeRequest(_ query: String?) -> Observable<Any> {
        guard let text = query else { return Observable.empty() }
        
        let request = USIGNormalizadorAPI.normalizar(direccion: text.trimmingCharacters(in: whitespace).lowercased(), excluyendo: exclusions, geocodificar: true, max: maxResults)

        searchController.searchBar.isLoading = true

        return provider
            .request(request)
            .mapJSON()
            .catchErrorJustReturn(["Error": true])
    }

    private func handleResults(_ results: Any) {
        self.results = []
        searchController.searchBar.isLoading = false

        guard let json = results as? [String: Any] else {
            reloadTable()

            return
        }

        guard let addresses = json["direccionesNormalizadas"] as? Array<[String: Any]>, addresses.count > 0 else {
            if let message = json["errorMessage"] as? String, message.lowercased().contains("calle inexistente") || message.lowercased().contains("no existe a la altura") {
                state = .notFound
            }
            else {
                state = .error
            }

            reloadTable()

            return
        }

        var isEqual = false
        var insertRow = false
        var deleteRow = false

        for item in addresses {
            let coordinates = item["coordenadas"] as? [String: Any]
            
            let address = USIGNormalizadorAddress(
                address: (item["direccion"] as! String).trimmingCharacters(in: whitespace).uppercased(),
                street: (item["nombre_calle"] as! String).trimmingCharacters(in: whitespace),
                number: item["altura"] as? Int,
                type: (item["tipo"] as! String).trimmingCharacters(in: whitespace),
                corner: item["nombre_calle_cruce"] as? String,
                latitude: USIGNormalizador.parseCoordinate(fromDict: coordinates, key: "y"),
                longitude: USIGNormalizador.parseCoordinate(fromDict: coordinates, key: "x"),
                districtCode: item["cod_partido"] as? String
            )

            self.results.append(address)

            if !forceNormalization {
                let searchText = searchController.searchBar.textField?.text?.trimmingCharacters(in: whitespace).uppercased()

                if searchText == address.address.replacingOccurrences(of: addressSufix, with: "") {
                    isEqual = true

                    if showPin ? (rowsInFirstSection == 2) : (rowsInFirstSection == 1) {
                        deleteRow = !hideForceNormalizationCell
                    }
                }
            }
        }

        if !forceNormalization {
            insertRow = !isEqual && !deleteRow && shouldHaveRowsInFirstSection()
        }

        if insertRow || deleteRow {
            DispatchQueue.main.async { [unowned self] in
                self.table.reloadSections(IndexSet(integer: 1), with: .none)

                if insertRow {
                    self.hideForceNormalizationCell = false
                    self.table.insertRows(at: [IndexPath(row: self.rowsInFirstSection - 1, section: 0)], with: .automatic)
                }
                else {
                    self.hideForceNormalizationCell = true
                    self.table.deleteRows(at: [IndexPath(row: self.rowsInFirstSection - 1, section: 0)], with: .automatic)
                }
            }
        }
        else {
            reloadTable()
        }
    }

    private func handleError(_ error: Swift.Error) {
        debugPrint(error)

        searchController.searchBar.isLoading = false
        state = .error
    }

    private func handleSelectedItem(indexPath: IndexPath) {
        if indexPath.section == 1 {
            let result = self.results[indexPath.row]

            guard (result.number != nil && result.type == "calle_altura") || result.type == "calle_y_calle" else {
                DispatchQueue.main.async { [unowned self] in
                    self.results = []

                    self.results.append(result)
                    self.table.reloadSections(IndexSet(integer: 1), with: .none)

                    if !self.forceNormalization {
                        self.hideForceNormalizationCell = true
                        self.table.reloadSections(IndexSet(integer: 0), with: .none)
                    }

                    self.searchController.searchBar.textField?.text = result.street + " "
                }

                return
            }

            value = result

            delegate?.didSelectValue(self, value: result)
        } else {
            if showPin && indexPath.row == 0 {
                delegate?.didSelectPin(self)
            }
            else if !forceNormalization, let cell = table.cellForRow(at: indexPath), let text = cell.textLabel?.text {
                delegate?.didSelectUnnormalizedAddress(self, value: text)
            }
        }

        close()
    }
    
    private func shouldHaveRowsInFirstSection() -> Bool {
        return showPin ? (rowsInFirstSection == 1) : (rowsInFirstSection == 0 && !hideForceNormalizationCell)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo: NSDictionary = (notification as NSNotification).userInfo as NSDictionary?,
            let keyboardFrame: NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as? NSValue else { return }
        
        DispatchQueue.main.async {
            self.tableBottomConstraint.constant = keyboardFrame.cgRectValue.height
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        DispatchQueue.main.async {
            self.tableBottomConstraint.constant = 0
        }
    }

    private func reloadTable() {
        DispatchQueue.main.async {
            self.table.reloadData()
            self.table.reloadEmptyDataSet()
        }
    }

    func close() {
        if self.navigationController?.viewControllers[0] === self {
            searchController.dismiss(animated: true) { [unowned self] in
                self.dismiss(animated: true) {
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
            self.onDismissCallback?(self)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - Extensions

extension USIGNormalizadorController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return section == 1 ? results.count : rowsInFirstSection }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if indexPath.section == 1 {
            cell.imageView?.image = nil
            cell.textLabel?.attributedText = results[indexPath.row].address.replacingOccurrences(of: addressSufix, with: "").highlight(searchController.searchBar.textField?.text)
        }
        else if showPin && indexPath.row == 0 {
            let attributes = [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

            cell.imageView?.image = pinImage
            cell.imageView?.tintColor = pinColor
            cell.textLabel?.attributedText = NSAttributedString(string: pinText, attributes: attributes)
        }
        else if !forceNormalization && !hideForceNormalizationCell, let text = searchController.searchBar.textField?.text?.trimmingCharacters(in: whitespace) {
            let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]

            cell.imageView?.image = nil
            cell.textLabel?.attributedText = NSAttributedString(string: text, attributes: attributes)
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
        let halfTableHeight = (scrollView as! UITableView).tableFooterView!.frame.size.height / 2
        let halfFirstSectionHeight = table.contentSize.height / 2
        
        return CGFloat(halfTableHeight + halfFirstSectionHeight)
    }
}

private extension String {
    func highlight(range boldRange: NSRange) -> NSAttributedString {
        let fontSize = UIFont.systemFontSize

        let bold = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: fontSize)]
        let nonBold = [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)]
        let attributedString = NSMutableAttributedString(string: self, attributes: nonBold)

        attributedString.setAttributes(bold, range: boldRange)

        return attributedString
    }

    func highlight(_ text: String?) -> NSAttributedString {
        let haystack = self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let substring = text, let range = haystack.range(of: substring.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else {
            return highlight(range: NSRange(location: 0, length: 0))
        }

        let needle = substring.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lower16 = range.lowerBound.samePosition(in: haystack.utf16)
        let start = haystack.utf16.distance(from: haystack.utf16.startIndex, to: lower16)

        return highlight(range: NSRange(location: start, length: needle.characters.count))
    }
}

fileprivate extension UISearchBar {
    // From: https://stackoverflow.com/questions/37692809/uisearchcontroller-with-loading-indicator
    fileprivate var textField: UITextField? {
        return subviews.first?.subviews.flatMap { $0 as? UITextField }.first
    }

    // From: https://stackoverflow.com/questions/37692809/uisearchcontroller-with-loading-indicator
    fileprivate var activityIndicator: UIActivityIndicatorView? {
        return textField?.leftView?.subviews.flatMap { $0 as? UIActivityIndicatorView }.first
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
