//
//  Component.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// Migration note:
// RxSwift replacement mapping:
// - No Rx type was used here in upstream RIBs.
// - This file keeps the original `NSRecursiveLock` + `[String: Any]` cache.
// - The Swift Concurrency migration added `@MainActor` to make the old
//   main-thread-only convention explicit.

import Foundation

@MainActor
open class Component<DependencyType>: Dependency {

	public let dependency: DependencyType

	private let lock = NSRecursiveLock()
	private var sharedInstances = [String: Any]()

	public init(dependency: DependencyType) {
		self.dependency = dependency
	}

	public final func shared<T>(__function: String = #function, _ factory: () -> T) -> T {
		self.lock.lock()
		defer { lock.unlock() }

		if let instance = (sharedInstances[__function] as? T?) ?? nil {
			return instance
		}

		let instance = factory()
		sharedInstances[__function] = instance

		return instance
	}
}

@MainActor
open class EmptyComponent: EmptyDependency {

	public init() {}
}
