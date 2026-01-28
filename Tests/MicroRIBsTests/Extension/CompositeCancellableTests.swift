//
//  CompositeCancellableTests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("CompositeCancellable 테스트")
struct CompositeCancellableTests {
	
	final class MockCancellable: AnyCancellableTask, @unchecked Sendable {
		var isCancelled = false
		
		func cancel() {
			isCancelled = true
		}
	}
	
	@Test("cancel() 호출 시 모든 작업 취소")
	func test_cancel_cancelsAll() {
		// Given
		let composite = CompositeCancellable()
		let task1 = MockCancellable()
		let task2 = MockCancellable()
		
		composite.insert(task1)
		composite.insert(task2)
		
		// When
		composite.cancel()
		
		// Then
		#expect(task1.isCancelled)
		#expect(task2.isCancelled)
	}
	
	@Test("취소된 상태에서 insert 시 즉시 취소")
	func test_insert_afterCancel() {
		// Given
		let composite = CompositeCancellable()
		composite.cancel()
		
		let task = MockCancellable()
		
		// When
		composite.insert(task)
		
		// Then
		#expect(task.isCancelled)
	}
	
	@Test("remove 호출 시 해당 작업 취소")
	func test_remove_cancelsSpecificTask() {
		// Given
		let composite = CompositeCancellable()
		let task1 = MockCancellable()
		let task2 = MockCancellable()
		
		let key1 = composite.insert(task1)
		composite.insert(task2)
		
		// When
		composite.remove(for: key1)
		
		// Then
		#expect(task1.isCancelled)
		#expect(!task2.isCancelled)
	}
	
	@Test("deinit 시 모든 작업 취소")
	func test_deinit_cancelsAll() {
		// Given
		var composite: CompositeCancellable? = CompositeCancellable()
		let task = MockCancellable()
		composite?.insert(task)
		
		// When
		composite = nil
		
		// Then
		#expect(task.isCancelled)
	}
}
