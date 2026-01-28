//
//  Router.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

import Foundation

public enum RouterLifecycle {
	case didLoad
}

public protocol RouterScope: AnyObject {
	var lifecycle: AsyncStream<RouterLifecycle>  { get }
}

public protocol Routing: RouterScope {
	var interactable: Interactable { get }

	var children: [Routing] { get }

	func load()

	func attachChild(_ child: Routing)

	func detachChild(_ child: Routing)
}

open class Router<InteractorType>: Routing {

	public let interactor: InteractorType

	public let interactable: Interactable

	public final var children: [Routing] {
		lock.lock()
		defer { lock.unlock() }
		return _children
	}

	public final var lifecycle: AsyncStream<RouterLifecycle> {
		return lifecycleSubject.stream
	}

	var deinitCancellables = CompositeCancellable()

	private var didLoadFlag: Bool = false
	private let lifecycleSubject = PassthroughAsyncSubject<RouterLifecycle>()
	private let lock = NSLock()
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

	public func attachChild(_ child: Routing) {
		lock.lock()
		assert(!(_children.contains { $0 === child }), "Attempt to attach child: \(child), which is already attached to \(self).")

		_children.append(child)
		lock.unlock()

		child.interactable.activate()
		child.load()
	}

	public func detachChild(_ child: Routing) {
		child.interactable.deactivate()

		lock.lock()
		_children.removeElementByReference(child)
		lock.unlock()
	}


	func internalDidLoad() {
		bindSubtreeActiveState()
		lifecycleSubject.send(.didLoad)
	}

	private func bindSubtreeActiveState() {
		let task = Task { [weak self] in

			guard let stream = self?.interactable.isActiveStream else { return }
			
			for await isActive in stream {
				self?.setSubtreeActive(isActive)
			}
		}

		_ = deinitCancellables.insert(task)
	}

	private func setSubtreeActive(_ active: Bool) {
		if active {
			iterateSubtree(self) { router in
				if !router.interactable.isActive {
					router.interactable.activate()
				}
			}
		} else {
			iterateSubtree(self) { router in
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
		lock.lock()
		let childrenToDetach = _children
		lock.unlock()

		for child in childrenToDetach {
			detachChild(child)
		}
	}

	deinit {
		interactable.deactivate()

		if !children.isEmpty {
			detachAllChildren()
		}

		lifecycleSubject.finish()

		deinitCancellables.cancel()

		LeakDetector.instance.expectDeallocate(object: interactable)
	}
}

