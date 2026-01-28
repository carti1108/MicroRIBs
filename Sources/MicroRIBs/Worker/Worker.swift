//
//  Worker.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/6/26.
//

import Foundation

public protocol Working: AnyObject {

	func start(_ interactorScope: InteractorScope)

	func stop()

	var isStarted: Bool { get }

	var isStartedStream: AsyncStream<Bool> { get }
}

open class Worker: Working {

	public final var isStarted: Bool {
		return isStartedSubject.value
	}

	public final var isStartedStream: AsyncStream<Bool> {
		return isStartedSubject.stream
	}

	public init() {}

	public final func start(_ interactorScope: InteractorScope) {
		guard !isStarted else {
			return
		}

		stop()
		isStartedSubject.send(true)

		let weakInteractorScope = WeakInteractorScope(sourceScope: interactorScope)
		bind(to: weakInteractorScope)
	}

	open func didStart(_ interactorScope: InteractorScope) {

	}

	public final func stop() {
		guard isStarted else {
			return
		}

		isStartedSubject.send(false)
		executeStop()
	}

	open func didStop() {

	}

	private let isStartedSubject = CurrentValueAsyncStream<Bool>(false)
	fileprivate var workerCancellable: CompositeCancellable?
	private var interactorBindingCancellable: AnyCancellableTask?

	private func bind(to interactorScope: InteractorScope) {
		unbindInteractor()

		interactorBindingCancellable = Task { [weak self] in

			for await isInteractorActive in interactorScope.isActiveStream {
				if isInteractorActive {
					if self?.isStarted == true {
						self?.executeStart(interactorScope)
					}
				} else {
					self?.executeStop()
				}
			}
		}
	}

	private func executeStart(_ interactorScope: InteractorScope) {
		workerCancellable = CompositeCancellable()
		didStart(interactorScope)
	}

	private func executeStop() {
		guard let cancellable = self.workerCancellable else {
			return
		}

		cancellable.cancel()
		self.workerCancellable = nil

		didStop()
	}

	private func unbindInteractor() {
		interactorBindingCancellable?.cancel()
		interactorBindingCancellable = nil
	}

	deinit {
		stop()
		unbindInteractor()
		isStartedSubject.finish()
	}
}

// MARK: - AnyCancellable Extension

public extension Task {

	@discardableResult
	func cancelOnStop(_ worker: Worker) -> Task {
		if let compositeCancellable = worker.workerCancellable {
			compositeCancellable.insert(self)
		} else {
			self.cancel()
			print("Task immediately cancelled, since \(worker) is stopped.")
		}

		return self
	}
}

// MARK: - WeakInteractorScope

fileprivate class WeakInteractorScope: InteractorScope {

	weak var sourceScope: InteractorScope?

	var isActive: Bool {
		return sourceScope?.isActive ?? false
	}

	var isActiveStream: AsyncStream<Bool> {
		return sourceScope?.isActiveStream ?? AsyncStream { continuation in
			continuation.yield(false)
			continuation.finish()
		}
	}

	fileprivate init(sourceScope: InteractorScope? = nil) {
		self.sourceScope = sourceScope
	}
}
