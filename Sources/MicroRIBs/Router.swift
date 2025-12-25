//
//  Router.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

@MainActor
public protocol Routing: AnyObject {

	var interactable: Interactable { get }

	var children: [Routing] { get }

	func attachChild(_ child: Routing)

	func detachChild(_ child: Routing)

	func didLoad()
}

@MainActor
open class Router<InteractorType>: Routing {

	public let interactor: InteractorType

	public let interactable: Interactable

	public private(set) final var children: [Routing] = []

	public init(interactor: InteractorType) {
		self.interactor = interactor
		guard let interactable = interactor as? Interactable else {
			fatalError("\(interactor) should conform to \(Interactable.self)")
		}
		self.interactable = interactable
	}

	public func attachChild(_ child: any Routing) {
		guard !children.contains(where: { $0 === child }) else {
			print("⚠️ Child router is already attached.")
			return
		}
		self.children.append(child)
		child.didLoad()
		child.interactable.activate()
	}

	public func detachChild(_ child: any Routing) {
		child.interactable.deactivate()
		self.children.removeAll(where: { $0 as AnyObject === child as AnyObject })

		LeakDetector.instance.expectDeallocate(object: child)

		if let viewableRouter = child as? ViewableRouting {
			viewableRouter.detachFromParent()
		}
	}

	open func didLoad() {}
}

