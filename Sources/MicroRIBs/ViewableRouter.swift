//
//  ViewableRouter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/23/25.
//

@MainActor
public protocol ViewableRouting: Routing {

	var viewControllable: ViewControllable { get }

	func detachFromParent()
}

@MainActor
open class ViewableRouter<InteractorType, ViewControllerType>: Router<InteractorType>, ViewableRouting {

	public let viewControllable: ViewControllable

	public let viewController: ViewControllerType

	public init(interactor: InteractorType, viewController: ViewControllerType) {
		self.viewController = viewController
		guard let viewControllable = viewController as? ViewControllable else {
			fatalError("\(viewController) should conform to \(ViewControllable.self)")
		}
		self.viewControllable = viewControllable

		super.init(interactor: interactor)
	}

	public func detachFromParent() {
		LeakDetector.instance.expectViewControllerDisappear(viewController: self.viewControllable.uiViewController)
	}
}

