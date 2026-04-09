//
//  PassthroughAsyncSubject.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

// Migration note:
// RxSwift replacement mapping:
// - `PublishSubject<Element>()` -> `PassthroughAsyncSubject<Element>()`
// - `subject.onNext(value)` -> `subject.send(value)`
// - `subject.asObservable()` -> `subject.stream`
// - `subject.onCompleted()` -> `subject.finish()`

import Foundation

public final class PassthroughAsyncSubject<Value: Sendable>: @unchecked Sendable {

	private let lock = NSLock()
	private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
	private var finished = false

	public init() {}

	public var stream: AsyncStream<Value> {
		AsyncStream { continuation in
			let id = UUID()

			self.lock.lock()
			if self.finished {
				self.lock.unlock()
				continuation.finish()
				return
			}

			self.continuations[id] = continuation
			self.lock.unlock()

			continuation.onTermination = { [weak self] _ in
				guard let self = self else { return }
				self.lock.lock()
				self.continuations[id] = nil
				self.lock.unlock()
			}
		}
	}

	public func send(_ value: Value) {
		self.lock.lock()
		guard !self.finished else {
			self.lock.unlock()
			return
		}

		let currentContinuations = self.continuations.values
		self.lock.unlock()

		for continuation in currentContinuations {
			continuation.yield(value)
		}
	}

	public func finish() {
		self.lock.lock()
		guard !self.finished else {
			self.lock.unlock()
			return
		}
		self.finished = true
		let currentContinuations = self.continuations.values
		self.continuations.removeAll()
		self.lock.unlock()

		for continuation in currentContinuations {
			continuation.finish()
		}
	}

	deinit {
		self.finish()
	}
}
