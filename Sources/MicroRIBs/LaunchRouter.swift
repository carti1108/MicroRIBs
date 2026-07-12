//
//  LaunchRouter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/23/25.
//

// RxSwift replacement mapping:
// - No Rx type was used here in upstream RIBs.
// - The Swift Concurrency migration here is `@MainActor` isolation only.

import UIKit

/// The base protocol for the root router of an application.
@MainActor
public protocol LaunchRouting: ViewableRouting {

	/// Launches the router tree.
	///
	/// - Parameter window: The application window to launch from.
	func launch(from window: UIWindow)
}

/// The base class of the root router of an application.
@MainActor
open class LaunchRouter<InteractorType, ViewControllerType>: ViewableRouter<InteractorType, ViewControllerType>, LaunchRouting {

	/// Initializer.
	///
	/// - Parameters:
	///   - interactor: The corresponding `Interactor` of this `Router`.
	///   - viewController: The corresponding `ViewController` of this `Router`.
	public override init(interactor: InteractorType, viewController: ViewControllerType) {
		super.init(interactor: interactor, viewController: viewController)
	}

	/// Launches the router tree.
	///
	/// - Parameter window: The application window to launch from.
	@MainActor
	public final func launch(from window: UIWindow) {
		window.rootViewController = viewControllable.uiViewController
		window.makeKeyAndVisible()

		interactable.activate()
		load()
	}
}
