//
//  ViewableRouter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/23/25.
//

import Foundation

public protocol ViewableRouting: Routing {
	var viewControllable: ViewControllable { get }
}

open class ViewableRouter<InteractorType, ViewControllerType>: Router<InteractorType>, ViewableRouting {

	public let viewController: ViewControllerType

	public let viewControllable: ViewControllable

	private var viewControllerDisappearExpectation: LeakDetectionHandle?

	public init(interactor: InteractorType, viewController: ViewControllerType) {
		self.viewController = viewController
		guard let viewControllable = viewController as? ViewControllable else {
			fatalError("\(viewController)는 \(ViewControllable.self)를 conform해야 합니다")
		}
		self.viewControllable = viewControllable
		super.init(interactor: interactor)
	}

	open override func didLoad() {
		super.didLoad()
		self.setupViewControllerLeakDetection()
	}

	private func setupViewControllerLeakDetection() {
		let task = Task { @MainActor [weak self] in
			guard let self = self else { return }

			for await isActive in self.interactable.isActiveStream {
				self.viewControllerDisappearExpectation?.cancel()
				self.viewControllerDisappearExpectation = nil

				if !isActive {
					let viewController = self.viewControllable.uiViewController
					self.viewControllerDisappearExpectation = LeakDetector.instance.expectViewControllerDisappear(viewController: viewController)
				}
			}
		}

		_ = deinitCancellables.insert(task)
	}

	deinit {
		LeakDetector.instance.expectDeallocate(object: viewController as AnyObject)
	}
}
