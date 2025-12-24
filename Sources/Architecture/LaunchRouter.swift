//
//  LaunchRouter.swift
//  Architecture
//
//  Created by Kiseok on 12/23/25.
//

import UIKit

@MainActor
public protocol LaunchRouting: ViewableRouting {

	func launch(from window: UIWindow)
}

open class LaunchRouter<InteractorType, ViewControllerType>: ViewableRouter<InteractorType, ViewControllerType>, LaunchRouting {

	public override init(interactor: InteractorType, viewController: ViewControllerType) {
		super.init(interactor: interactor, viewController: viewController)
	}

	@MainActor
	public final func launch(from window: UIWindow) {
		window.rootViewController = viewControllable.uiViewController
		window.makeKeyAndVisible()

		self.interactable.activate()
		self.didLoad()
	}
}
