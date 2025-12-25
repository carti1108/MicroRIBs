//
//  Presenter.swift
//  Architecture
//
//  Created by Kiseok on 12/25/25.
//

public protocol Presentable: AnyObject {}

open class Presenter<ViewControllerType>: Presentable {

	public let viewController: ViewControllerType

	public init(viewController: ViewControllerType) {
		self.viewController = viewController
	}
}
