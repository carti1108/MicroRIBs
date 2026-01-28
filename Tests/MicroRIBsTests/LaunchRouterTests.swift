//
//  LaunchRouterTests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import UIKit
@testable import MicroRIBs

@Suite("LaunchRouter 테스트")
@MainActor
struct LaunchRouterTests {

	final class MockInteractable: Interactable, @unchecked Sendable {
		let isActiveSubject = CurrentValueAsyncStream<Bool>(false)

		var isActive: Bool { isActiveSubject.value }
		var isActiveStream: AsyncStream<Bool> { isActiveSubject.stream }

		var activateCallCount = 0
		var deactivateCallCount = 0

		func activate() {
			guard !isActive else { return }  // 중복 호출 방지
			activateCallCount += 1
			isActiveSubject.send(true)
		}

		func deactivate() {
			guard isActive else { return }  // 중복 호출 방지
			deactivateCallCount += 1
			isActiveSubject.send(false)
		}
	}

	final class MockViewController: UIViewController, ViewControllable, @unchecked Sendable {
	}

	final class TestLaunchRouter: LaunchRouter<MockInteractable, MockViewController> {
		var didLoadCallCount = 0

		override func didLoad() {
			super.didLoad()
			MainActor.assumeIsolated {
				didLoadCallCount += 1
			}
		}
	}

	@Test("launch 호출 시 Window 설정 및 Interactor 활성화 확인")
	func test_launch() {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()
		let router = TestLaunchRouter(interactor: interactor, viewController: viewController)
		let window = UIWindow()

		// When
		router.launch(from: window)

		// Then
		#expect(window.rootViewController === viewController)
		#expect(window.isKeyWindow)
		#expect(interactor.activateCallCount == 1)
		#expect(router.didLoadCallCount == 1)
	}
	
	@Test("launch 중복 호출 시 안전하게 처리되는지 확인")
	func test_launch_multipleCalls() {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()
		let router = TestLaunchRouter(interactor: interactor, viewController: viewController)
		let window = UIWindow()
		
		// When
		router.launch(from: window)
		router.launch(from: window)
		router.launch(from: window)
		
		// Then
		#expect(interactor.activateCallCount == 1, "activate는 한 번만 호출되어야 합니다")
		#expect(router.didLoadCallCount == 1, "didLoad는 한 번만 호출되어야 합니다")
		#expect(window.rootViewController === viewController)
		#expect(window.isKeyWindow)
	}
}
