//
//  Interactor.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// Migration note:
// RxSwift replacement mapping:
// - `private let isActiveSubject = BehaviorSubject<Bool>(value: false)`
//   -> `private let isActiveSubject = CurrentValueAsyncStream<Bool>(false)`
// - `var isActiveStream: Observable<Bool>` -> `var isActiveStream: AsyncStream<Bool>`
// - `try isActiveSubject.value()` -> `isActiveSubject.value`
// - `isActiveSubject.onNext(true/false)` -> `isActiveSubject.send(true/false)`
// - `isActiveSubject.onCompleted()` -> `isActiveSubject.finish()`
// - `fileprivate var activenessDisposable: CompositeDisposable?`
//   -> `fileprivate var activenessCancellables: CompositeCancellable?`
// - Rx `Disposable.disposeOnDeactivate(interactor:)`
//   -> `Task.cancelOnDeactivate(interactor:)` / `Task.disposeOnDeactivate(interactor:)`

import Foundation
import AsyncAlgorithms

@MainActor
public protocol InteractorScope: AnyObject {

	var isActive: Bool { get }

	var isActiveStream: AsyncStream<Bool> { get }
}

@MainActor
public protocol Interactable: InteractorScope {

	func activate()

	func deactivate()
}

@MainActor
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

	isolated deinit {
		if self.isActive {
			self.deactivate()
		}
		self.isActiveSubject.finish()
	}
}

public extension AsyncSequence {

	@MainActor
	func confineTo(_ interactorScope: InteractorScope) -> AsyncStream<Element> {
		// RxSwift replacement mapping:
		// - `Observable.combineLatest(interactorScope.isActiveStream, self)`
		//   -> `AsyncAlgorithms.combineLatest(interactorScope.isActiveStream, self)`
		// - `.filter { isActive, value in isActive }` -> same
		// - `.map { isActive, value in value }` -> same
		// - resulting `Observable<Element>` -> `AsyncStream<Element>`
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

	@MainActor
	@discardableResult
	func cancelOnDeactivate(interactor: Interactor) -> Task {
		// RxSwift replacement mapping:
		// - `Disposable.disposeOnDeactivate(interactor:)` -> `Task.cancelOnDeactivate(interactor:)`
		// - `activenessDisposable.insert(disposable)` -> `activenessCancellables.insert(task)`
		// - `disposable.dispose()` -> `task.cancel()`
		if let cancellables = interactor.activenessCancellables {
			cancellables.insert(self)
		} else {
			self.cancel()
			print("Subscription immediately terminated, since \(interactor) is inactive.")
		}

		return self
	}

	@MainActor
	@discardableResult
	func disposeOnDeactivate(interactor: Interactor) -> Task {
		// Migration alias so existing RIBs call sites can replace
		// `disposable.disposeOnDeactivate(...)` with `task.disposeOnDeactivate(...)`.
		cancelOnDeactivate(interactor: interactor)
	}
}
