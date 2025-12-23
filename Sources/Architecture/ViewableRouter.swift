//
//  ViewableRouter.swift
//  Architecture
//
//  Created by Kiseok on 12/23/25.
//

public protocol ViewableRouting: Routing {

	var viewControllable: ViewControllable { get }
}

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
}
