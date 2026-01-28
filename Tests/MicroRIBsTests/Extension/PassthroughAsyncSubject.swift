//
//  PassthroughAsyncSubject.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("PassthroughAsyncSubject 테스트")
struct PassthroughAsyncSubjectTests {
	
	@Test("구독 이후에 보낸 값만 정상적으로 수신되는지 확인")
	func test_send_receivesValuesAfterSubscription() async {
		// Given
		let subject = PassthroughAsyncSubject<Int>()
		var receivedValues: [Int] = []
		
		let task = Task {
			for await value in subject.stream {
				receivedValues.append(value)
			}
			return receivedValues
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		subject.send(1)
		subject.send(2)
		subject.finish()
		
		let result = await task.value
		
		// Then
		#expect(result == [1, 2])
	}
	
	@Test("다수의 구독자가 동시에 값을 수신하는지 확인")
	func test_multipleSubscribers_receiveValues() async {
		// Given
		let subject = PassthroughAsyncSubject<String>()
		
		let task1 = Task {
			var values: [String] = []
			for await value in subject.stream {
				values.append(value)
			}
			return values
		}
		
		let task2 = Task {
			var values: [String] = []
			for await value in subject.stream {
				values.append(value)
			}
			return values
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		subject.send("Event")
		subject.finish()
		
		let result1 = await task1.value
		let result2 = await task2.value
		
		// Then
		#expect(result1 == ["Event"])
		#expect(result2 == ["Event"])
	}
	
	@Test("finish 호출 시 스트림이 종료되는지 확인")
	func test_finish_terminatesStream() async {
		// Given
		let subject = PassthroughAsyncSubject<Int>()
		var finished = false
		
		let task = Task {
			for await _ in subject.stream {}
			finished = true
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		subject.finish()
		
		_ = await task.result
		
		// Then
		#expect(finished)
	}
	
	@Test("이미 종료된 Subject에 구독 시 즉시 종료되는지 확인")
	func test_subscribeAfterFinish_terminatesImmediately() async {
		// Given
		let subject = PassthroughAsyncSubject<Int>()
		subject.finish()
		
		// When
		var receivedCount = 0
		for await _ in subject.stream {
			receivedCount += 1
		}
		
		// Then
		#expect(receivedCount == 0)
	}
	
	@Test("종료된 이후 send 호출 시 값이 전달되지 않는지 확인")
	func test_sendAfterFinish_ignored() async {
		// Given
		let subject = PassthroughAsyncSubject<Int>()
		var receivedValues: [Int] = []
		
		let task = Task {
			for await value in subject.stream {
				receivedValues.append(value)
			}
			return receivedValues
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		subject.send(1)
		subject.finish()
		subject.send(2)
		
		let result = await task.value
		
		// Then
		#expect(result == [1])
	}
	
	@Test("deinit 시 스트림이 자동으로 종료되는지 확인")
	func test_deinit_terminatesStream() async {
		// Given
		var subject: PassthroughAsyncSubject<Int>? = PassthroughAsyncSubject()
		var finished = false
		
		let task = Task {
			for await _ in subject!.stream { }
			finished = true
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		subject = nil
		
		_ = await task.result
		
		// Then
		#expect(finished)
	}
}
