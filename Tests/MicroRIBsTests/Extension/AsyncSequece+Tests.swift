//
//  AsyncSequece+Tests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("AsyncSequence Extension 테스트")
struct AsyncSequenceExtensionTests {
	
	@Test("정상적인 값들이 순서대로 잘 전달되는지 확인")
	func test_valuesAreStreamed() async {
		let sourceStream = AsyncStream<Int> { continuation in
			continuation.yield(1)
			continuation.yield(2)
			continuation.yield(3)
			continuation.finish()
		}
		
		// When
		let erasedStream = sourceStream.eraseToStream()
		
		// Then
		var result: [Int] = []
		for await value in erasedStream {
			result.append(value)
		}
		
		#expect(result == [1, 2, 3], "소스 시퀀스의 값이 순서대로 전달되어야 합니다.")
	}
	
	@Test("소스에서 에러가 발생하면 스트림이 (에러 없이) 조용히 종료되는지 확인")
	func test_errorSilencing() async {
		// Given
		let sourceStream = AsyncThrowingStream<Int, Error> { continuation in
			continuation.yield(100)
			continuation.finish(throwing: NSError(domain: "TestError", code: -1))
		}
		
		// When
		let erasedStream = sourceStream.eraseToStream()
		
		// Then
		var result: [Int] = []
		for await value in erasedStream {
			result.append(value)
		}
		
		#expect(result == [100], "에러 발생 전의 값은 전달되고, 에러 발생 시 스트림이 종료되어야 합니다.")
	}
	
	@Test("외부 Task가 취소되면 내부 소스 시퀀스 구독도 취소되는지 확인")
	func test_cancellationPropagation() async {
		// Given
		await confirmation("Source stream should be terminated", expectedCount: 1) { confirm in
			let sourceStream = AsyncStream<Int> { continuation in
				continuation.onTermination = { _ in
					confirm()
				}
				
				continuation.yield(1)
			}
			
			let erasedStream = sourceStream.eraseToStream()
			
			// When
			let consumeTask = Task {
				for await _ in erasedStream {
					
				}
			}
			
			while consumeTask.isCancelled == false {
				await Task.yield()
				try? await Task.sleep(nanoseconds: 1_000_000)
				consumeTask.cancel()
			}
		}
	}
}
