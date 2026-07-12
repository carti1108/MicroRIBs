//
//  Builder.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// RxSwift replacement mapping:
// Uber RIBs `Buildable` / `Builder` stay structurally the same here.
// The Swift Concurrency migration is the `@MainActor` isolation, which
// replaces the old "builders are called on main thread by convention" rule.

/// The base builder protocol that all builders should conform to.
@MainActor
public protocol Buildable: AnyObject {}

/// The base class for all builders.
///
/// Builders are responsible for instantiating the RIBs and their dependencies.
@MainActor
open class Builder<DependencyType>: Buildable {

	/// The dependency used to instantiate this RIB.
	public let dependency: DependencyType

	/// Initializer.
	///
	/// - Parameter dependency: The dependency used to instantiate this RIB.
	public init(dependency: DependencyType) {
		self.dependency = dependency
	}
}
