//
//  Interactor.swift
//  Architecture
//
//  Created by Kiseok on 12/20/25.
//

public protocol Interactable: AnyObject {
	func didBecomeActive()

	func willResignActive()
}

open class Interactor: Interactable {

	public init() {}

	open func didBecomeActive() {}

	open func willResignActive() {}
}
