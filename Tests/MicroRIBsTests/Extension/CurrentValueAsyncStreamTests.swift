//
//  CurrentValueAsyncStreamTests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("CurrentValueAsyncStream 테스트")
struct CurrentValueAsyncStreamTests {
	
	@Test("초기값 확인")
	func test_initialValue() {
		// Given
		let stream = CurrentValueAsyncStream(10)
		
		// Then
		#expect(stream.value == 10)
	}
	
	@Test("구독 시 초기값 즉시 수신 및 새로운 값 업데이트 확인")
	func test_stream_receivesInitialAndUpdates() async {
		// Given
		let stream = CurrentValueAsyncStream(0)
		var receivedValues: [Int] = []
		
		let task = Task {
			for await value in stream.stream {
				receivedValues.append(value)
				if value == 2 { break }
			}
			return receivedValues
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		stream.send(1)
		stream.send(2)
		
		let result = await task.value
		
		// Then
		#expect(result == [0, 1, 2])
		#expect(stream.value == 2)
	}
	
	@Test("다수의 구독자가 동시에 값을 수신하는지 확인")
	func test_multipleSubscribers() async {
		// Given
		let stream = CurrentValueAsyncStream("A")
		
		let task1 = Task {
			var values: [String] = []
			for await value in stream.stream {
				values.append(value)
			}
			return values
		}
		
		let task2 = Task {
			var values: [String] = []
			for await value in stream.stream {
				values.append(value)
			}
			return values
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		stream.send("B")
		stream.finish()
		
		let result1 = await task1.value
		let result2 = await task2.value
		
		// Then
		#expect(result1 == ["A", "B"])
		#expect(result2 == ["A", "B"])
	}
	
	@Test("finish 호출 시 스트림이 정상 종료되는지 확인")
	func test_finish_terminatesStream() async {
		// Given
		let stream = CurrentValueAsyncStream(1)
		var finished = false
		
		let task = Task {
			for await _ in stream.stream {}
			finished = true
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		stream.finish()
		
		_ = await task.result
		
		// Then
		#expect(finished)
	}
	
	@Test("종료된 스트림에 구독 시 값 방출 없이 즉시 종료되는지 확인")
	func test_subscribeAfterFinish() async {
		// Given
		let stream = CurrentValueAsyncStream(1)
		stream.finish()
		
		// When
		var receivedCount = 0
		for await _ in stream.stream {
			receivedCount += 1
		}
		
		// Then
		#expect(receivedCount == 0)
	}
	
	@Test("종료 후 send 호출 시 값이 무시되는지 확인")
	func test_sendAfterFinish_isIgnored() async {
		// Given
		let stream = CurrentValueAsyncStream(1)
		var values: [Int] = []
		
		let task = Task {
			for await value in stream.stream {
				values.append(value)
			}
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		stream.finish()
		stream.send(2)
		
		_ = await task.result
		
		// Then
		#expect(values == [1])
	}
	
	@Test("deinit 발생 시 스트림이 종료되는지 확인")
	func test_deinit_finishesStream() async {
		// Given
		var stream: CurrentValueAsyncStream<Int>? = CurrentValueAsyncStream(100)
		var finished = false
		
		let task = Task {
			for await _ in stream!.stream {}
			finished = true
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		
		// When
		stream = nil
		
		_ = await task.result
		
		// Then
		#expect(finished)
	}
}
