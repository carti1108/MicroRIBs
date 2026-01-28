//
//  AnyCancelTaskBag.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

import Foundation

public final class AnyCancelTaskBag {

	private let lock = NSLock()

	private var tasks: [any AnyCancellableTask] = .init()

	public init() {}

	public func insert(_ task: any AnyCancellableTask) {
		self.lock.lock()
		self.tasks.append(task)
		self.lock.unlock()
	}

	private func cancel() {
		self.lock.lock()
		self.tasks.forEach { $0.cancel() }
		self.tasks.removeAll()
		self.lock.unlock()
	}

	deinit {
		self.cancel()
	}
}

public extension Task {
	func store(in bag: AnyCancelTaskBag) {
		bag.insert(self)
	}
}
