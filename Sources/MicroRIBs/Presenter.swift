//
//  Presenter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/25/25.
//

// Migration note:
// RxSwift replacement mapping:
// - No Rx type was used here in upstream RIBs.
// - The Swift Concurrency migration here is `@MainActor` isolation only.

@MainActor
public protocol Presentable: AnyObject {}

@MainActor
open class Presenter<ViewControllerType>: Presentable {

	public let viewController: ViewControllerType

	public init(viewController: ViewControllerType) {
		self.viewController = viewController
	}
}
