//
//  CompositeCancellable.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

import Foundation

public final class CompositeCancellable: @unchecked Sendable {

	public typealias Key = UUID

	private let lock = NSLock()
	private var subscriptions: [Key: AnyCancellableTask] = [:]
	private var isCancelled = false

	public init() {}

	@discardableResult
	public func insert(_ cancellable: AnyCancellableTask) -> Key {
		lock.lock()
		defer { lock.unlock() }

		let key = UUID()

		if isCancelled {
			cancellable.cancel()
		} else {
			subscriptions[key] = cancellable
		}

		return key
	}

	public func remove(for key: Key) {
		lock.lock()
		let cancellable = subscriptions.removeValue(forKey: key)
		lock.unlock()

		cancellable?.cancel()
	}

	public func cancel() {
		lock.lock()
		guard !isCancelled else {
			lock.unlock()
			return
		}

		isCancelled = true
		let currentSubscriptions = subscriptions.values
		subscriptions.removeAll()
		lock.unlock()

		for item in currentSubscriptions {
			item.cancel()
		}
	}

	deinit {
		cancel()
	}
}
