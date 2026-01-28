//
//  InteractorTests.swift
//  MicroRIBsTests
//
//  Created by Test on 1/10/26.
//

import Testing
import Foundation
import AsyncAlgorithms
@testable import MicroRIBs

@Suite("Interactor 테스트")
struct InteractorTests {
	
	final class MockInteractor: Interactor, @unchecked Sendable {
		var didBecomeActiveCallCount = 0
		var willResignActiveCallCount = 0
		
		override func didBecomeActive() {
			super.didBecomeActive()
			didBecomeActiveCallCount += 1
		}
		
		override func willResignActive() {
			super.willResignActive()
			willResignActiveCallCount += 1
		}
	}
	
	@Test("activate 호출 시 상태 변경 및 메서드 호출 확인")
	func test_activate() {
		// Given
		let interactor = MockInteractor()
		
		// When
		interactor.activate()
		
		// Then
		#expect(interactor.isActive == true)
		#expect(interactor.didBecomeActiveCallCount == 1)
		#expect(interactor.willResignActiveCallCount == 0)
	}
	
	@Test("deactivate 호출 시 상태 변경 및 메서드 호출 확인")
	func test_deactivate() {
		// Given
		let interactor = MockInteractor()
		interactor.activate()
		
		// When
		interactor.deactivate()
		
		// Then
		#expect(interactor.isActive == false)
		#expect(interactor.didBecomeActiveCallCount == 1)
		#expect(interactor.willResignActiveCallCount == 1)
	}
	
	@Test("이미 활성화된 상태에서 중복 activate 호출 방지")
	func test_activate_idempotency() {
		// Given
		let interactor = MockInteractor()
		interactor.activate()
		
		// When
		interactor.activate()
		
		// Then
		#expect(interactor.didBecomeActiveCallCount == 1)
	}
	
	@Test("cancelOnDeactivate 동작 확인")
	func test_cancelOnDeactivate() async {
		// Given
		let interactor = Interactor()
		interactor.activate()
		
		let task = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}
		task.cancelOnDeactivate(interactor: interactor)
		
		// When
		interactor.deactivate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(task.isCancelled == true)
	}
	
	@Test("비활성 상태에서 cancelOnDeactivate 호출 시 즉시 취소")
	func test_cancelOnDeactivate_immediateCancel() async {
		// Given
		let interactor = Interactor()
		let task = Task {
			try? await Task.sleep(nanoseconds: 1_000_000_000)
		}
		
		// When
		task.cancelOnDeactivate(interactor: interactor)
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(task.isCancelled == true)
	}
	
	@Test("confineTo 스트림 필터링 확인")
	func test_confineTo() async {
		// Given
		let interactor = Interactor()
		let (stream, continuation) = AsyncStream<Int>.makeStream()
		let task = Task {
			var values: [Int] = []
			for await value in stream.confineTo(interactor) {
				values.append(value)
			}
			return values
		}
		
		// When
		continuation.yield(1)
		try? await Task.sleep(nanoseconds: 10_000_000)
		interactor.activate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		continuation.yield(2)
		try? await Task.sleep(nanoseconds: 10_000_000)
		interactor.deactivate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		continuation.yield(3)
		task.cancel()
		
		// Then
		let receivedValues = await task.value
		
		#expect(receivedValues.contains(2))
		#expect(!receivedValues.contains(3))
	}
	
	@Test("활성화 시 직전 값(1)과 새로운 값(2)이 수신되는지 확인")
	func test_confineTo_combineLatest_behavior() async {
		// Given
		let interactor = Interactor()
		let (stream, continuation) = AsyncStream<Int>.makeStream(bufferingPolicy: .unbounded)
		
		let task = Task {
			var values: [Int] = []
			for await value in stream.confineTo(interactor) {
				values.append(value)
			}
			return values
		}
		
		// When
		continuation.yield(1)
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		interactor.activate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		continuation.yield(2)
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		interactor.deactivate()
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		continuation.yield(3)
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		task.cancel()
		
		// Then
		let result = await task.value
		#expect(result == [1, 2], "활성화 시점의 최신값(1)과 활성 중 받은 값(2)이 들어와야 함. 실제값: \(result)")
	}
	
	@Test("deinit 시 자동 deactivate 확인")
	func test_deinit() async {
		// Given
		var interactor: MockInteractor? = MockInteractor()
		interactor?.activate()
		let stream = interactor!.isActiveStream
		
		// When
		interactor = nil
		
		// Then
		var finished = false
		for await _ in stream { }
		finished = true
		
		#expect(finished)
	}
}
