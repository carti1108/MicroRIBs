//
//  CurrentValueAsyncStream.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

// Migration note:
// RxSwift replacement mapping:
// - `BehaviorSubject<Element>(value: initialValue)` -> `CurrentValueAsyncStream<Element>(initialValue)`
// - `BehaviorRelay<Element>(value: initialValue)` -> `CurrentValueAsyncStream<Element>(initialValue)`
// - `subject.value()` / `relay.value` -> `stream.value`
// - `subject.onNext(value)` / `relay.accept(value)` -> `stream.send(value)`
// - `subject.asObservable()` -> `stream.stream`
// - `subject.onCompleted()` -> `stream.finish()`

import Foundation

public final class CurrentValueAsyncStream<Value: Sendable>: @unchecked Sendable {
	private let lock = NSLock()
	private var _value: Value
	private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]
	private var finished = false

	public init(_ initialValue: Value) {
		self._value = initialValue
	}

	public var value: Value {
		self.lock.lock()
		defer { self.lock.unlock() }
		return self._value
	}

	public var stream: AsyncStream<Value> {
		AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
			let id = UUID()

			self.lock.lock()
			if finished {
				self.lock.unlock()
				continuation.finish()
				return
			}
			let current = self._value
			self.continuations[id] = continuation
			continuation.yield(current)

			self.lock.unlock()

			continuation.onTermination = { [weak self] _ in
				guard let self else { return }
				self.lock.lock()
				self.continuations[id] = nil
				self.lock.unlock()
			}
		}
	}

	public func send(_ newValue: Value) {
		self.lock.lock()
		guard !finished else {
			self.lock.unlock()
			return
		}
		self._value = newValue
		let currentContinuations = Array(continuations.values)
		self.lock.unlock()

		currentContinuations.forEach { $0.yield(newValue) }
	}

	public func finish() {
		self.lock.lock()
		guard !finished else {
			self.lock.unlock()
			return
		}
		self.finished = true
		let currentContinuations = Array(self.continuations.values)
		self.continuations.removeAll()
		self.lock.unlock()

		currentContinuations.forEach { $0.finish() }
	}

	deinit {
		self.finish()
	}
}
