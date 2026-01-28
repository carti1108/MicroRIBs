//
//  Array+.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/8/26.
//

import Foundation

public extension Array {

	mutating func removeElementByReference(_ element: Element) {
		guard let objIndex = firstIndex(where: { $0 as AnyObject === element as AnyObject }) else {
			return
		}
		remove(at: objIndex)
	}
}
