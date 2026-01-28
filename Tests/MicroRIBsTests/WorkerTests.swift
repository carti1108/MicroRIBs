//
//  WorkerTests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("Worker 테스트")
struct WorkerTests {

	final class MockInteractorScope: InteractorScope, @unchecked Sendable {
		let isActiveSubject = CurrentValueAsyncStream<Bool>(false)

		var isActive: Bool { isActiveSubject.value }
		var isActiveStream: AsyncStream<Bool> { isActiveSubject.stream }

		func setActive(_ value: Bool) {
			isActiveSubject.send(value)
		}
	}

	final class TestWorker: Worker, @unchecked Sendable {
		var didStartCallCount = 0
		var didStopCallCount = 0

		override func didStart(_ interactorScope: InteractorScope) {
			super.didStart(interactorScope)
			didStartCallCount += 1
		}

		override func didStop() {
			super.didStop()
			didStopCallCount += 1
		}
	}

	@Test("Interactor가 Active 상태일 때 start 호출 시 didStart가 실행되는지 확인")
	func test_start_whenInteractorActive() async {
		// Given
		let interactorScope = MockInteractorScope()
		interactorScope.setActive(true)
		let worker = TestWorker()

		// When
		worker.start(interactorScope)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(worker.isStarted == true)
		#expect(worker.didStartCallCount == 1)
		#expect(worker.didStopCallCount == 0)
	}

	@Test("Interactor가 Inactive 상태일 때 start하면 대기하다가, Active 될 때 didStart 실행되는지 확인")
	func test_start_whenInteractorInactive_thenActive() async {
		// Given
		let interactorScope = MockInteractorScope()
		interactorScope.setActive(false)
		let worker = TestWorker()

		worker.start(interactorScope)
		try? await Task.sleep(nanoseconds: 10_000_000)

		#expect(worker.didStartCallCount == 0)

		// When
		interactorScope.setActive(true)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(worker.didStartCallCount == 1)
	}

	@Test("동작 중 Interactor가 꺼지면 Worker도 멈추고(didStop), 다시 켜지면 재시작(didStart)하는지 확인")
	func test_interactor_toggling() async {
		// Given
		let interactorScope = MockInteractorScope()
		interactorScope.setActive(true)
		let worker = TestWorker()
		worker.start(interactorScope)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// When
		interactorScope.setActive(false)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(worker.didStopCallCount == 1)
		#expect(worker.isStarted == true)

		// When
		interactorScope.setActive(true)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(worker.didStartCallCount == 2)
	}

	@Test("수동으로 stop 호출 시 didStop이 실행되고 상태가 변경되는지 확인")
	func test_manual_stop() async {
		// Given
		let interactorScope = MockInteractorScope()
		interactorScope.setActive(true)
		let worker = TestWorker()
		worker.start(interactorScope)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// When
		worker.stop()

		// Then
		#expect(worker.isStarted == false)
		#expect(worker.didStopCallCount == 1)
	}

	@Test("cancelOnStop: Worker가 멈출 때 연결된 Task가 취소되는지 확인")
	func test_cancelOnStop() async {
		// Given
		let interactorScope = MockInteractorScope()
		interactorScope.setActive(true)
		let worker = TestWorker()
		worker.start(interactorScope)
		try? await Task.sleep(nanoseconds: 10_000_000)

		let task = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}

		// When
		task.cancelOnStop(worker)
		worker.stop()
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(task.isCancelled == true)
	}

	@Test("cancelOnStop: Worker가 이미 정지 상태일 때 호출하면 즉시 취소되는지 확인 (Edge Case)")
	func test_cancelOnStop_whenWorkerIsStopped() async {
		// Given
		let worker = TestWorker()

		let task = Task {
			try? await Task.sleep(nanoseconds: 1_000_000_000)
		}

		// When
		task.cancelOnStop(worker)
		try? await Task.sleep(nanoseconds: 10_000_000)

		// Then
		#expect(task.isCancelled == true)
	}

	@Test("deinit 시 자동으로 stop 되어 리소스가 정리되는지 확인")
	func test_deinit_stopsWorker() async {
		// Given
		let interactorScope = MockInteractorScope()
		interactorScope.setActive(true)

		var worker: TestWorker? = TestWorker()
		worker?.start(interactorScope)
		try? await Task.sleep(nanoseconds: 10_000_000)

		let isStartedStream = worker!.isStartedStream

		// When
		worker = nil

		// Then
		var finished = false
		for await _ in isStartedStream { }
		finished = true

		#expect(finished)
	}
}
