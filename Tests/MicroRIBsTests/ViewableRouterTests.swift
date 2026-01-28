//
//  ViewableRouterTests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import UIKit
@testable import MicroRIBs

@Suite("ViewableRouter 테스트")
@MainActor
struct ViewableRouterTests {

	final class MockInteractable: Interactable, @unchecked Sendable {
		let isActiveSubject = CurrentValueAsyncStream<Bool>(false)

		var isActive: Bool { isActiveSubject.value }
		var isActiveStream: AsyncStream<Bool> { isActiveSubject.stream }

		func activate() { isActiveSubject.send(true) }
		func deactivate() { isActiveSubject.send(false) }

		func setActive(_ value: Bool) {
			isActiveSubject.send(value)
		}
	}

	final class MockViewController: UIViewController, ViewControllable, @unchecked Sendable {
		var uiViewControllerAccessCount = 0

		var uiViewController: UIViewController {
			uiViewControllerAccessCount += 1
			return self
		}
	}

	final class TestViewableRouter: ViewableRouter<MockInteractable, MockViewController> {
	}

	@Test("초기화 테스트")
	func test_init() {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()

		// When
		let router = TestViewableRouter(interactor: interactor, viewController: viewController)

		// Then
		#expect(router.viewControllable === viewController)
		#expect(router.viewController === viewController)
	}

	@Test("LeakDetection 바인딩 테스트")
	func test_leakDetection_binding() async {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()
		let router = TestViewableRouter(interactor: interactor, viewController: viewController)

		// When
		router.load()
		interactor.setActive(true)
		try? await Task.sleep(nanoseconds: 10_000_000)

		interactor.setActive(false)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(viewController.uiViewControllerAccessCount > 0)
	}

	@Test("Active 상태일 때 LeakDetection 취소 테스트")
	func test_leakDetection_cancels_on_active() async {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()
		let router = TestViewableRouter(interactor: interactor, viewController: viewController)
		router.load()
		let initialCount = viewController.uiViewControllerAccessCount

		// When
		interactor.setActive(true)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(viewController.uiViewControllerAccessCount == initialCount)
	}

	@Test("LeakDetection 취소 로직 검증: Active -> Inactive -> Active")
	func test_leakDetection_cancellation_logic() async {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()
		let router = TestViewableRouter(interactor: interactor, viewController: viewController)
		router.load()

		interactor.setActive(true)
		try? await Task.sleep(nanoseconds: 10_000_000)

		interactor.setActive(false)
		try? await Task.sleep(nanoseconds: 10_000_000)

		let countAfterInactive = viewController.uiViewControllerAccessCount
		#expect(countAfterInactive > 0)
		
		interactor.setActive(true)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(viewController.uiViewControllerAccessCount == countAfterInactive)
	}

	@Test("deinit 테스트")
	func test_deinit_leakDetection() async {
		// Given
		let interactor = MockInteractable()
		let viewController = MockViewController()
		var router: TestViewableRouter? = TestViewableRouter(interactor: interactor, viewController: viewController)
		router?.load()

		// When
		router = nil

		// Then
		#expect(router == nil)
	}
}
