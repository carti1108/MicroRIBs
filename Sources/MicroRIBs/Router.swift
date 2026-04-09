//
//  Router.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// Migration note:
// RxSwift replacement mapping:
// - `private let lifecycleSubject = PublishSubject<RouterLifecycle>()`
//   -> `private let lifecycleSubject = PassthroughAsyncSubject<RouterLifecycle>()`
// - `var lifecycle: Observable<RouterLifecycle>` -> `var lifecycle: AsyncStream<RouterLifecycle>`
// - `lifecycleSubject.onNext(.didLoad)` -> `lifecycleSubject.send(.didLoad)`
// - `lifecycleSubject.onCompleted()` -> `lifecycleSubject.finish()`
// - Rx subscription to `interactable.isActiveStream`
//   -> retained `Task` iterating `interactable.isActiveStream`
// - `CompositeDisposable` for router teardown -> `CompositeCancellable`

import Foundation

@MainActor
public enum RouterLifecycle {
	case didLoad
}

@MainActor
public protocol RouterScope: AnyObject {
	var lifecycle: AsyncStream<RouterLifecycle>  { get }
}

@MainActor
public protocol Routing: RouterScope {
	var interactable: Interactable { get }
	var children: [Routing] { get }

	func load()
	func attachChild(_ child: Routing)
	func detachChild(_ child: Routing)
}

@MainActor
open class Router<InteractorType>: Routing {

	public let interactor: InteractorType

	public let interactable: Interactable

	public final var children: [Routing] {
		return _children
	}

	public final var lifecycle: AsyncStream<RouterLifecycle> {
		return lifecycleSubject.stream
	}

	var deinitCancellables = CompositeCancellable()

	private var didLoadFlag: Bool = false
	private let lifecycleSubject = PassthroughAsyncSubject<RouterLifecycle>()
	private var _children: [Routing] = []

	public init(interactor: InteractorType) {
		self.interactor = interactor

		guard let interactable = interactor as? Interactable else {
			fatalError("\(interactor) should conform to \(Interactable.self)")
		}

		self.interactable = interactable
	}

	public final func load() {
		guard !didLoadFlag else {
			return
		}

		didLoadFlag = true
		internalDidLoad()
		didLoad()
	}

	open func didLoad() {
	}

	public final func attachChild(_ child: Routing) {
		assert(!(_children.contains { $0 === child }), "Attempt to attach child: \(child), which is already attached to \(self).")

		_children.append(child)

		child.interactable.activate()
		child.load()
	}

	public final func detachChild(_ child: Routing) {
		child.interactable.deactivate()
		_children.removeElementByReference(child)
	}


	func internalDidLoad() {
		bindSubtreeActiveState()
		lifecycleSubject.send(.didLoad)
	}

	private func bindSubtreeActiveState() {
		let initialIsActive = interactable.isActive
		let stream = interactable.isActiveStream

		// Rx `BehaviorSubject` subscription in upstream RIBs eagerly observes the
		// current lifecycle state. Bootstrap it synchronously before the task
		// starts so attach/load semantics stay deterministic.
		setSubtreeActive(initialIsActive)

		// RxSwift replacement mapping:
		// - `interactable.isActiveStream.subscribe(onNext:)`
		//   -> `Task { for await isActive in interactable.isActiveStream { ... } }`
		let task = Task { @MainActor [weak self] in
			guard let self = self else { return }
			var didObserveInitialValue = false

			for await isActive in stream {
				if !didObserveInitialValue {
					didObserveInitialValue = true
					if isActive == initialIsActive {
						continue
					}
				}
				self.setSubtreeActive(isActive)
			}
		}

		_ = deinitCancellables.insert(task)
	}

	private func setSubtreeActive(_ active: Bool) {
		iterateSubtree(self) { router in
			if active {
				if !router.interactable.isActive {
					router.interactable.activate()
				}
			} else {
				if router.interactable.isActive {
					router.interactable.deactivate()
				}
			}
		}
	}

	private func iterateSubtree(_ root: Routing, closure: (_ node: Routing) -> Void) {
		closure(root)
		for child in root.children {
			iterateSubtree(child, closure: closure)
		}
	}

	private func detachAllChildren() {
		let childrenToDetach = _children

		for child in childrenToDetach {
			detachChild(child)
		}
	}

	isolated deinit {
		self.interactable.deactivate()

		if !children.isEmpty {
			detachAllChildren()
		}

		lifecycleSubject.finish()
		deinitCancellables.cancel()

		LeakDetector.instance.expectDeallocate(object: interactable)
	}
}
