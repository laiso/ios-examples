//
//  SignInTests.swift
//  SignInTests
//
//  Created by laiso on 2017/04/06.
//  Copyright © 2017 laiso. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
import RxBlocking
@testable import SignIn

class SignInViewModelTests: XCTestCase {
    
    private let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    struct SignInMock: SignIn {
        func sendRequest(email: String, password: String) -> Observable<String> {
            switch email {
            case "200":
                return .just("")
            default:
                return .error(SignInMock.error)
            }
        }
        
        static let error = NSError(domain: "test.hoge", code: 999, userInfo: nil)
    }
    
    func testSigInSuccess() {
        let viewModel = ViewModel(
            emailText: Observable.just("200"),
            passwordText: Observable.just("pass"),
            submitButtonTap: Observable.just(),
            signIn: SignInMock()
        )
        
        let tapCount = try! viewModel.nextViewPushing.toBlocking(timeout: 1).toArray()
        XCTAssertEqual(tapCount.count, 1)
    }
    
    func testSigInFailure() {
        let viewModel = ViewModel(
            emailText: Observable.just("401"),
            passwordText: Observable.just("pass"),
            submitButtonTap: Observable.just(),
            signIn: SignInMock()
        )
        
        viewModel.nextViewPushing.subscribe().disposed(by: self.disposeBag)
        let error = viewModel.requestError.value as? NSError
        XCTAssertEqual(error, SignInMock.error)
    }
}
