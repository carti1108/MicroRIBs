//
//  ArrayExtensionTests.swift
//  MicroRIBsTests
//
//  Created by Test on 1/10/26.
//

import Testing
import Foundation
@testable import MicroRIBs

@Suite("Array Extension 테스트")
struct ArrayExtensionTests {
	final class MockItem: @unchecked Sendable {
		let id: Int
		init(id: Int) { self.id = id }
	}
	
	@Test("참조(주소)가 동일한 요소를 정확히 제거하는지 확인")
	func test_removeElementByReference_removesCorrectInstance() {
		// Given
		let item1 = MockItem(id: 1)
		let item2 = MockItem(id: 2)
		var array = [item1, item2]
		
		// When
		array.removeElementByReference(item1)
		
		// Then
		#expect(array.count == 1)
		#expect(array.first === item2, "item1은 지워지고 item2만 남아야 함")
	}
	
	@Test("내용(프로퍼티)은 같지만 다른 인스턴스인 경우 제거되지 않아야 함")
	func test_removeElementByReference_checksIdentity() {
		// Given
		let originalItem = MockItem(id: 100)
		let sameValueItem = MockItem(id: 100)
		
		var array = [originalItem]
		
		// When
		array.removeElementByReference(sameValueItem)
		
		// Then
		#expect(array.count == 1, "주소가 다르므로 지워지면 안 됨")
		#expect(array.first === originalItem, "원래 객체가 그대로 있어야 함")
	}
	
	@Test("배열에 없는 요소를 제거하려 할 때 안전하게 처리되는지 확인")
	func test_removeElementByReference_notFound() {
		// Given
		let item1 = MockItem(id: 1)
		let newItem = MockItem(id: 2)
		var array = [item1]
		
		// When
		array.removeElementByReference(newItem)
		
		// Then
		#expect(array.count == 1)
		#expect(array.first === item1)
	}
	
	@Test("중복된 객체가 있을 경우 첫 번째 요소만 제거되는지 확인 (firstIndex 동작)")
	func test_removeElementByReference_removesFirstOccurrence() {
		// Given
		let item = MockItem(id: 1)
		var array = [item, item]
		
		// When
		array.removeElementByReference(item)
		
		// Then
		#expect(array.count == 1, "하나만 지워져야 함")
		#expect(array.first === item, "나머지 하나는 남아있어야 함")
	}
}
