//
//  Interactor.swift
//  Architecture
//
//  Created by Kiseok on 12/20/25.
//

public protocol Interactable: AnyObject {

	var isActive: Bool { get }

	func activate()

	func deactivate()

	func didBecomeActive()

	func willResignActive()
}

open class Interactor: Interactable {

	public private(set) var isActive: Bool = false

	public init() {}

	public func activate() {
		guard !isActive else { return }
		isActive = true
		didBecomeActive()
	}

	public func deactivate() {
		guard isActive else { return }
		willResignActive()
		isActive = false
	}

	open func didBecomeActive() {}

	open func willResignActive() {}
}
