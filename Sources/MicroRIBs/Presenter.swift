//
//  Presenter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/25/25.
//

// RxSwift replacement mapping:
// - No Rx type was used here in upstream RIBs.
// - The Swift Concurrency migration here is `@MainActor` isolation only.

/// The base protocol for all `Presenter`s.
@MainActor
public protocol Presentable: AnyObject {}

/// The base class for all `Presenter`s.
@MainActor
open class Presenter<ViewControllerType>: Presentable {

	/// The `ViewController` associated with this `Presenter`.
	public let viewController: ViewControllerType

	/// Initializer.
	///
	/// - Parameter viewController: The `ViewController` associated with this `Presenter`.
	public init(viewController: ViewControllerType) {
		self.viewController = viewController
	}
}
