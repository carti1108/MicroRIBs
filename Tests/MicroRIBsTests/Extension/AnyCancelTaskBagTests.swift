//
//  AnyCancelTaskBagTests.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/27/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("AnyCancelTaskBag 테스트")
struct AnyCancelTaskBagTests {

	@Test("Bag을 nil로 만들면 내부 Task가 취소되어야 한다")
	func test_bagDeinit_cancelsTask() async throws {
		var bag: AnyCancelTaskBag? = AnyCancelTaskBag()

		let task = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}
		task.store(in: bag!)
		bag = nil
		try? await Task.sleep(nanoseconds: 10_000_000)

		#expect(task.isCancelled == true, "가방이 nil이 되면 태스크는 취소되어야 함")
	}
	
	@Test("여러 Task를 추가한 후 모두 취소되는지 확인")
	func test_bagDeinit_cancelsMultipleTasks() async {
		// Given
		var bag: AnyCancelTaskBag? = AnyCancelTaskBag()
		
		let task1 = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}
		
		let task2 = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}
		
		let task3 = Task {
			while !Task.isCancelled {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}
		
		task1.store(in: bag!)
		task2.store(in: bag!)
		task3.store(in: bag!)
		
		// When
		bag = nil
		try? await Task.sleep(nanoseconds: 10_000_000)
		
		// Then
		#expect(task1.isCancelled == true, "첫 번째 Task가 취소되어야 함")
		#expect(task2.isCancelled == true, "두 번째 Task가 취소되어야 함")
		#expect(task3.isCancelled == true, "세 번째 Task가 취소되어야 함")
	}
}
