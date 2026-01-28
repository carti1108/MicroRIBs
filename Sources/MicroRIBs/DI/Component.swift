//
//  Component.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

import Foundation

open class Component<DependencyType>: Dependency {

	// MARK: - Public Properties

	public let dependency: DependencyType

	// MARK: - Private Properties

	private let lock = NSRecursiveLock()

	private var sharedInstances = [String: Any]()

	// MARK: - Initialization

	public init(dependency: DependencyType) {
		self.dependency = dependency
	}

	// MARK: - Public Methods

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
