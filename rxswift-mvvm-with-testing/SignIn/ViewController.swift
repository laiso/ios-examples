//
//  ViewController.swift
//  SignIn
//
//  Copyright © 2017 laiso. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    private var viewModel: ViewModel!
    private let disposeBag = DisposeBag()

    enum StoryboardID: String {
        case home
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ViewModel(
            emailText: emailField.rx.text.orEmpty.asObservable(),
            passwordText: passwordField.rx.text.orEmpty.asObservable(),
            submitButtonTap: submitButton.rx.tap.asObservable()
        )
        
        viewModel.nextViewPushing.asDriver(onErrorJustReturn: ())
            .drive(onNext: pushToHome)
            .addDisposableTo(disposeBag)
        
        viewModel.requestError.asObservable()
            .filter { $0 != nil }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: showError(error:))
            .addDisposableTo(disposeBag)
    }
    
    private func pushToHome() {
        guard let storyboard = self.storyboard,
              let nav = self.navigationController else { return }
        
        let viewController = storyboard.instantiateViewController(withIdentifier: StoryboardID.home.rawValue)
        nav.pushViewController(viewController, animated: true)
    }
    
    private func showError(error: Swift.Error?) {
        let alert = UIAlertController(title: nil, message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

struct ViewModel {
    let nextViewPushing: Observable<Void>
    //let requestError = PublishSubject<Swift.Error>()
    let requestError = Variable<Swift.Error?>(nil)
    
    init(
        emailText: Observable<String> = Observable.empty(),
        passwordText: Observable<String> = Observable.empty(),
        submitButtonTap: Observable<Void> = Observable.empty(),
        signIn: SignIn = SignInImpl(httpClient: URLSession.shared)
        ) {
     
        let requestError = self.requestError
        
        let fields = Observable.combineLatest(emailText, passwordText)
        
        nextViewPushing = submitButtonTap.withLatestFrom(fields)
            .flatMapLatest { statusCode, password -> Observable<String> in
                return signIn
                    .sendRequest(email: statusCode, password: password)
                    .catchError { e in
                        requestError.value = e
                        return Observable.empty()
                    }
            }
            .do(onNext: { debugPrint($0) })
            .map { _ in () }
    }
}

protocol SignIn {
    func sendRequest(email: String, password: String) -> Observable<String>
}

struct SignInImpl: SignIn {
    let httpClient: URLSession
    
    func sendRequest(email: String, password: String) -> Observable<String> {
        let url = URL(string: "https://httpbin.org/status/\(email)")!
        let req = URLRequest(url: url)
        return httpClient.rx.data(request: req)
            .map { String(data: $0, encoding: .utf8) ?? "" }
    }
}
