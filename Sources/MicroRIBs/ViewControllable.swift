//
//  ViewControllable.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// Migration note:
// RxSwift replacement mapping:
// - No Rx type was used here in upstream RIBs.
// - `uiviewController` is kept as a compatibility alias for migrated RIBs code.

import UIKit

@MainActor
public protocol ViewControllable: AnyObject {

	var uiViewController: UIViewController { get }
}

public extension ViewControllable where Self: UIViewController {

	var uiViewController: UIViewController { self }
}

@MainActor
public extension ViewControllable {

	var uiviewController: UIViewController {
		uiViewController
	}

	func present(_ viewControllable: ViewControllable, animated: Bool, completion: (() -> Void)?) {
		self.uiViewController.present(viewControllable.uiViewController, animated: animated, completion: completion)
	}

	func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
		self.uiViewController.dismiss(animated: animated, completion: completion)
	}

	func pushViewController(_ viewControllable: ViewControllable, animated: Bool) {
		if let nav = self.uiViewController as? UINavigationController {
			nav.pushViewController(viewControllable.uiViewController, animated: animated)
		} else {
			self.uiViewController.navigationController?.pushViewController(viewControllable.uiViewController, animated: animated)
		}
	}

	func popViewController(animated: Bool) {
		if let nav = self.uiViewController as? UINavigationController {
			nav.popViewController(animated: animated)
		} else {
			self.uiViewController.navigationController?.popViewController(animated: animated)
		}
	}

	func popToRoot(animated: Bool) {
		if let nav = self.uiViewController as? UINavigationController {
			nav.popToRootViewController(animated: animated)
		} else {
			self.uiViewController.navigationController?.popToRootViewController(animated: animated)
		}
	}

	func setViewControllers(_ viewControllerables: [ViewControllable]) {
		if let nav = self.uiViewController as? UINavigationController {
			nav.setViewControllers(viewControllerables.map(\.uiViewController), animated: true)
		} else {
			self.uiViewController.navigationController?.setViewControllers(viewControllerables.map(\.uiViewController), animated: true)
		}
	}

	var topViewControllable: ViewControllable {
		var top: ViewControllable = self

		while let presented = top.uiViewController.presentedViewController as? ViewControllable {
			top = presented
		}

		return top
	}
}
