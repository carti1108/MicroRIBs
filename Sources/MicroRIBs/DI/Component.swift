//
//  Component.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

import Foundation

public protocol ComponentScope: AnyObject {

	var path: [String] { get }
}

open class Component<DependencyType>: Dependency, ComponentScope {

	public let dependency: DependencyType

	public weak var parent: ComponentScope?

	public init(dependency: DependencyType, parent: ComponentScope? = nil) {
		self.dependency = dependency
		self.parent = parent
	}

	public lazy var path: [String] = {
		let name = String(describing: type(of: self))
		if let parentPath = self.parent?.path {
			return parentPath + [name]
		}
		return [name]
	}()

	private let lock = NSRecursiveLock()
	private var sharedInstances = [String: Any]()

	public final func shared<T>(__function: String = #function, _ factory: () -> T) -> T {
		self.lock.lock()
		defer { lock.unlock() }

		if let instance = sharedInstances[__function] as? T {
			return instance
		}

		let instance = factory()
		sharedInstances[__function] = instance

		return instance
	}
}

open class EmptyComponent: EmptyDependency {

	public init() {}
}
