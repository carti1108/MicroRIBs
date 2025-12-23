//
//  Router.swift
//  Architecture
//
//  Created by Kiseok on 12/20/25.
//

public protocol Routing: AnyObject {

	var interactable: Interactable { get }

	var children: [Routing] { get }

	func attachChild(_ child: Routing)

	func detachChild(_ child: Routing)

	func start()

	func stop()
}

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
		self.children.append(child)
		child.start()
	}

	public func detachChild(_ child: any Routing) {
		child.stop()
		self.children.removeAll(where: { $0 as AnyObject === child as AnyObject })
	}

	public func start() {
		if let interactable = self.interactor as? Interactable {
			interactable.didBecomeActive()
		}
	}

	public func stop() {
		if let interactable = self.interactor as? Interactable {
			interactable.willResignActive()
		}
		self.children.forEach { $0.stop() }
		self.children.removeAll()
	}
}
