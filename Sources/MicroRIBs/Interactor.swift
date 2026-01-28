//
//  Interactor.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

import Foundation
import AsyncAlgorithms

public protocol InteractorScope: AnyObject {

	var isActive: Bool { get }

	var isActiveStream: AsyncStream<Bool> { get }
}

public protocol Interactable: InteractorScope {

	func activate()

	func deactivate()
}

open class Interactor: Interactable {

	public var isActive: Bool {
		return isActiveSubject.value
	}

	public var isActiveStream: AsyncStream<Bool> {
		return isActiveSubject.stream
	}

	private let isActiveSubject = CurrentValueAsyncStream<Bool>(false)
	fileprivate var activenessCancellables: CompositeCancellable?

	public init() {}

	public final func activate() {
		guard !isActive else { return }
		activenessCancellables = CompositeCancellable()
		isActiveSubject.send(true)
		didBecomeActive()
	}

	open func didBecomeActive() {

	}

	public final func deactivate() {
		guard isActive else { return }
		willResignActive()

		activenessCancellables?.cancel()
		activenessCancellables = nil

		isActiveSubject.send(false)
	}

	open func willResignActive() {

	}

	deinit {
		if self.isActive {
			self.deactivate()
		}
		self.isActiveSubject.finish()
	}
}

public extension AsyncSequence {

	func confineTo(_ interactorScope: InteractorScope) -> AsyncStream<Element> {
		return combineLatest(interactorScope.isActiveStream, self)
			.filter { isActive, value in
				isActive
			}
			.map { isActive, value in
				value
			}
			.eraseToStream()

	}
}

public extension Task {

	@discardableResult
	func cancelOnDeactivate(interactor: Interactor) -> Task {
		if let cancellables = interactor.activenessCancellables {
			cancellables.insert(self)
		} else {
			self.cancel()
			print("Subscription immediately terminated, since \(interactor) is inactive.")
		}

		return self
	}
}

