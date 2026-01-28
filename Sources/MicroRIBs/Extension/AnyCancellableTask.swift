//
//  AnyCancellableTask.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

import Foundation

public protocol AnyCancellableTask: Sendable {
	func cancel()
}

extension Task: AnyCancellableTask {}
