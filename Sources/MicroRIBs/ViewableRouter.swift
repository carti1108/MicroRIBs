//
//  ViewableRouter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/23/25.
//

// Migration note:
// RxSwift replacement mapping:
// - Rx subscription to `interactable.isActiveStream`
//   -> retained `Task` iterating `interactable.isActiveStream`
// - `deinitDisposable.insert(disposable)` -> `deinitCancellables.insert(task)`
// - upstream `viewControllable.uiviewController`
//   -> `viewControllable.uiViewController` / `uiviewController` alias
// The leak detection target and timing are kept aligned with upstream RIBs.

import Foundation

@MainActor
public protocol ViewableRouting: Routing {
	var viewControllable: ViewControllable { get }
}

@MainActor
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

	override func internalDidLoad() {
		self.setupViewControllerLeakDetection()
		super.internalDidLoad()
	}

	private func setupViewControllerLeakDetection() {
		let initialIsActive = interactable.isActive
		let stream = interactable.isActiveStream

		handleInteractableStateChange(initialIsActive)

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
				self.handleInteractableStateChange(isActive)
			}
		}

		_ = deinitCancellables.insert(task)
	}

	private func handleInteractableStateChange(_ isActive: Bool) {
		viewControllerDisappearExpectation?.cancel()
		viewControllerDisappearExpectation = nil

		if !isActive {
			let viewController = viewControllable.uiViewController
			viewControllerDisappearExpectation = LeakDetector.instance.expectViewControllerDisappear(viewController: viewController)
		}
	}

	isolated deinit {
		LeakDetector.instance.expectDeallocate(
			object: viewControllable.uiViewController,
			inTime: LeakDefaultExpectationTime.viewDisappear
		)
	}
}
