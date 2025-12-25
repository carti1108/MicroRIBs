//
//  Presenter.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/25/25.
//

@MainActor
public protocol Presentable: AnyObject {}

@MainActor
open class Presenter<ViewControllerType>: Presentable {

	public let viewController: ViewControllerType

	public init(viewController: ViewControllerType) {
		self.viewController = viewController
	}
}

