//
//  RouterTests.swift
//  MicroRIBsTests
//
//  Created by Test on 1/10/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("Router 기본 기능 및 트리 상태 전파 테스트")
struct RouterTests {
	
	// MARK: - Mocks (Spy)
	final class MockInteractable: Interactable, @unchecked Sendable {
		var isActive: Bool { isActiveSubject.value }
		var isActiveStream: AsyncStream<Bool> { isActiveSubject.stream }
		
		let isActiveSubject = CurrentValueAsyncStream<Bool>(false)
		
		var activateCallCount = 0
		var deactivateCallCount = 0
		
		func activate() {
			guard !isActive else { return }
			activateCallCount += 1
			isActiveSubject.send(true)
		}
		
		func deactivate() {
			guard isActive else { return }
			deactivateCallCount += 1
			isActiveSubject.send(false)
		}
	}
	
	final class TestRouter: Router<MockInteractable>, @unchecked Sendable {
		var didLoadCallCount = 0
		
		override func didLoad() {
			super.didLoad()
			didLoadCallCount += 1
		}
	}
	
	// MARK: - Tests
	
	@Test("attachChild: 자식을 붙이면 자식의 Interactor가 활성화되고 Router가 로드되는지 확인")
	func test_attachChild_activatesChild() {
		// Given
		let interactor = MockInteractable()
		let router = TestRouter(interactor: interactor)
		
		let childInteractor = MockInteractable()
		let childRouter = TestRouter(interactor: childInteractor)
		
		// When
		router.attachChild(childRouter)
		
		// Then
		#expect(router.children.count == 1)
		#expect(router.children.first === childRouter)
		#expect(childInteractor.activateCallCount == 1)
	}
	
	@Test("detachChild: 자식을 떼면 자식의 Interactor가 비활성화되는지 확인")
	func test_detachChild_deactivatesChild() {
		// Given
		let router = TestRouter(interactor: MockInteractable())
		let childInteractor = MockInteractable()
		let childRouter = TestRouter(interactor: childInteractor)
		
		router.attachChild(childRouter)
		
		// When
		router.detachChild(childRouter)
		
		// Then
		#expect(router.children.isEmpty)
		#expect(childInteractor.deactivateCallCount == 1)
	}
	
	@Test("bindSubtreeActiveState: 부모가 비활성화되면 자식들도 자동으로 비활성화되는지 확인")
	func test_subtree_propagation() async {
		// Given
		let parentInteractor = MockInteractable()
		let parentRouter = TestRouter(interactor: parentInteractor)
		
		let childInteractor = MockInteractable()
		let childRouter = TestRouter(interactor: childInteractor)
		
		parentRouter.attachChild(childRouter)
		parentInteractor.activate()
		parentRouter.load()

		try? await Task.sleep(nanoseconds: 10_000_000)
		
		#expect(childInteractor.isActive == true)
		
		parentInteractor.deactivate()
		
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(childInteractor.isActive == false, "부모가 꺼지면 자식도 꺼져야 합니다")
		
		// When
		parentInteractor.activate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(childInteractor.isActive == true, "부모가 켜지면 자식도 켜져야 합니다")
	}
	
	@Test("Router deinit 시 자식들을 모두 정리(Cleanup)하는지 확인")
	func test_deinit_cleansUpChildren() {
		// Given
		let interactor = MockInteractable()
		var router: TestRouter? = TestRouter(interactor: interactor)
		
		let childInteractor = MockInteractable()
		let childRouter = TestRouter(interactor: childInteractor)
		
		// 부모 Router 활성화 및 자식 추가
		interactor.activate()
		router?.attachChild(childRouter)
		
		// When
		router = nil
		
		// Then
		#expect(interactor.deactivateCallCount == 1, "부모 Interactor가 deactivate되어야 함")
		#expect(childInteractor.deactivateCallCount == 1, "자식 Interactor도 deactivate되어야 함")
	}
	
	@Test("load 중복 호출 시 didLoad가 한 번만 호출되는지 확인")
	func test_load_idempotency() {
		// Given
		let interactor = MockInteractable()
		let router = TestRouter(interactor: interactor)
		
		// When
		router.load()
		router.load()
		router.load()
		
		// Then
		#expect(router.didLoadCallCount == 1, "didLoad는 한 번만 호출되어야 합니다")
	}
	
	@Test("lifecycle 스트림이 didLoad 이벤트를 방출하는지 확인")
	func test_lifecycle_emitsDidLoad() async {
		// Given
		let interactor = MockInteractable()
		let router = TestRouter(interactor: interactor)
		
		var receivedEvents: [RouterLifecycle] = []
		let task = Task {
			for await event in router.lifecycle {
				receivedEvents.append(event)
				break
			}
		}

		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// When
		router.load()
		try? await Task.sleep(nanoseconds: 10_000_000)
		task.cancel()
		
		// Then
		#expect(receivedEvents.contains(.didLoad), "lifecycle 스트림은 didLoad 이벤트를 방출해야 합니다")
	}
	
	@Test("3단계 계층 구조에서 상태 전파 확인")
	func test_deepHierarchy_propagation() async {
		// Given
		let grandparentInteractor = MockInteractable()
		let grandparentRouter = TestRouter(interactor: grandparentInteractor)
		
		let parentInteractor = MockInteractable()
		let parentRouter = TestRouter(interactor: parentInteractor)
		
		let childInteractor = MockInteractable()
		let childRouter = TestRouter(interactor: childInteractor)
		
		grandparentRouter.attachChild(parentRouter)
		parentRouter.attachChild(childRouter)

		grandparentInteractor.activate()
		grandparentRouter.load()

		try? await Task.sleep(nanoseconds: 10_000_000)
		
		#expect(grandparentInteractor.isActive == true)
		#expect(parentInteractor.isActive == true)
		#expect(childInteractor.isActive == true)
		
		// When
		grandparentInteractor.deactivate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(grandparentInteractor.isActive == false)
		#expect(parentInteractor.isActive == false)
		#expect(childInteractor.isActive == false, "손자까지 모두 비활성화되어야 합니다")
		
		// When
		grandparentInteractor.activate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(grandparentInteractor.isActive == true)
		#expect(parentInteractor.isActive == true)
		#expect(childInteractor.isActive == true, "손자까지 모두 다시 활성화되어야 합니다")
	}
}
