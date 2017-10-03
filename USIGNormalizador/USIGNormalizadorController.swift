//
//  USIGViewController.swift
//  USIGNormalizadorController
//
//  Created by Rita Zerrizuela on 9/28/17.
//  Copyright © 2017 GCBA. All rights reserved.
//

import Foundation
import UIKit
import SwifterSwift
import DZNEmptyDataSet
import RxSwift
import RxCocoa
import Moya

fileprivate enum SearchState {
    case NotFound
    case Empty
    case Error
}

public class USIGNormalizadorController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var table: UITableView!
    
    // MARK: - Properties

    private var _value: USIGNormalizadorAddress?
    public var value: USIGNormalizadorAddress? { return _value }
    
    private var _max: Int = 10
    public var maxResults: Int {
        get {
            return _max
        }
        
        set {
            _max = newValue > 0 ? newValue : _max
        }
    }

    public var delegate: USIGNormalizadorControllerDelegate?
    fileprivate var provider: RxMoyaProvider<USIGNormalizadorAPI>!
    
    public var showPin: Bool = false
    public var pinImageTint: UIColor = UIColor.black
    public var pinButtonTint: UIColor = UIColor.black
    fileprivate var onDismissCallback: ((UIViewController) -> Void)?
    fileprivate var searchController: UISearchController!
    fileprivate var results: [USIGNormalizadorAddress] = []
    fileprivate var state: SearchState = .Empty
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate let whitespace: CharacterSet = .whitespacesAndNewlines
    
    // MARK: - Overrides
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupTableView()
        setupRx()
        
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
        searchController.searchBar.text = _value?.address.replacingOccurrences(of: ", CABA", with: "")
        
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
            .filter { [unowned self] _ in
                return self.filterSearch()
            }
            .flatMapLatest { [unowned self] query -> Observable<Any> in
                return self.makeRequest(query!)
            }
            .subscribe(onNext: handleResults, onError: handleError)
            .addDisposableTo(disposeBag)
        
        _ = table
            .rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                return self.handleSelectedItem(index: indexPath.row)
            })
    }
    
    // MARK: - Helper methods
    
    private func filterSearch() -> Bool {
        if let text = searchController.searchBar.text, text.trimmingCharacters(in: whitespace).characters.count > 0 { return true }
        else  {
            searchController.searchBar.textField?.text = self.searchController.searchBar.textField?.text?.trimmingCharacters(in: whitespace)
            state = .Empty
            results = []
            
            reloadTable()
            
            return false
        }
    }
    
    private func makeRequest(_ query: String) -> Observable<Any> {
        let exclusion = delegate?.exclude(self) ?? USIGNormalizadorExclusions.GBA.rawValue
        
        searchController.searchBar.isLoading = true
        
        return provider
            .request(USIGNormalizadorAPI.normalizar(direccion: query.trimmingCharacters(in: whitespace).lowercased(), excluyendo: exclusion, geocodificar: true, max: _max))
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
            if let message = json["errorMessage"] as? String, message.lowercased().contains("calle inexistente") {
                state = .NotFound
            }
            else {
                state = .Error
            }
            
            reloadTable()
            
            return
        }
        
        for item in addresses {
            let address = USIGNormalizadorAddress(address: (item["direccion"] as! String).trimmingCharacters(in: whitespace),
                                      street: (item["nombre_calle"] as! String).trimmingCharacters(in: whitespace),
                                      number: item["altura"] as? Int,
                                      type: (item["tipo"] as! String).trimmingCharacters(in: whitespace),
                                      corner: item["nombre_calle_cruce"] as? String)
            
            self.results.append(address)
        }
        
        reloadTable()
    }
    
    private func handleError(_ error: Swift.Error) {
        debugPrint(error)
        
        searchController.searchBar.isLoading = false
        state = .Error
    }
    
    private func handleSelectedItem(index: Int) {
        let result = self.results[index]
        
        guard (result.number != nil && result.type == "calle_altura") || result.type == "calle_y_calle" else {
            if result.type != "calle_y_calle" {
                searchController.searchBar.textField?.text = result.street + " "
            }
            
            return
        }
        
        _value = result
        
        delegate?.didChange(self, value: result)
        close(directly: false)
    }
    
    private func reloadTable() {
        DispatchQueue.main.async {
            self.table.reloadData()
        }
    }
    
    func close(directly: Bool = true) {
        searchController.dismiss(animated: true, completion: { [unowned self] in
            if !directly {
                self.dismiss(animated: true) {
                    self.onDismissCallback?(self)
                }
            }
            else {
                self.onDismissCallback?(self)
            }
        })
    }
}

// MARK: - Extensions

extension USIGNormalizadorController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.attributedText = results[indexPath.row].address
            .replacingOccurrences(of: ", CABA", with: "")
            .highlight(searchController.searchBar.textField?.text)
        
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
        close()
    }
}

extension USIGNormalizadorController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        switch state {
            case .Empty:
                return showPin ? UIImage(named: "PinSolid", in: Bundle(for: USIGNormalizador.self), compatibleWith: nil) : nil
            case .NotFound:
                return nil
            case .Error:
                return nil
        }
    }
    
    public func imageTintColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return pinButtonTint
    }
    
    public func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let title: String
        let attributes = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        
        switch state {
        case .Empty:
            title = ""
        case .NotFound:
            title = "No Encontrado"
        case .Error:
            title = "Error"
        }
        
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    public func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let description: String
        let attributes = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        
        switch state {
        case .Empty:
            description = ""
        case .NotFound:
            description = "La búsqueda no tuvo resultados."
        case .Error:
            description = "Asegurate de estar conectado a Internet."
        }
        
        return NSAttributedString(string: description, attributes: attributes)
    }
    
    public func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        switch self.state {
        case .Empty:
            let attributes = [NSForegroundColorAttributeName: pinButtonTint]
            
            return showPin ? NSAttributedString(string: "Fijar la ubicación en el mapa", attributes: attributes) : nil
        case .NotFound:
            return nil
        case .Error:
            return nil
        }
    }
    
    public func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        guard showPin else { return }
        
        delegate?.didSelectPin(self)
        close(directly: false)
    }
    
    public func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return CGFloat(-((UIScreen.main.bounds.size.height - scrollView.frame.size.height) / 2))
    }
}

private extension String {
    func highlight(range boldRange: NSRange) -> NSAttributedString {
        let fontSize = UIFont.systemFontSize
        
        let bold = [ NSFontAttributeName: UIFont.boldSystemFont(ofSize: fontSize) ]
        let nonBold = [ NSFontAttributeName: UIFont.systemFont(ofSize: fontSize) ]
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
