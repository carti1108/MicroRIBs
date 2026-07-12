//
//  Component.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// RxSwift replacement mapping:
// - No Rx type was used here in upstream RIBs.
// - The `shared` method was removed in favor of the new `@Shared` property wrapper.

import Foundation

/// The base class for all components.
///
/// Components provide dependency injection to the RIBs. Subclasses should
/// declare dependencies via `@Shared` property wrappers to ensure they are created exactly once.
@MainActor
open class Component<DependencyType>: Dependency {

	/// The dependency of this component.
	public let dependency: DependencyType

	/// Initializer.
	///
	/// - Parameter dependency: The dependency of this component.
	public init(dependency: DependencyType) {
		self.dependency = dependency
	}
}

/// The base class for an empty component.
@MainActor
open class EmptyComponent: EmptyDependency {

	/// Initializer.
	public init() {}
}
