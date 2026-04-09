//
//  Builder.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// Migration note:
// Uber RIBs `Buildable` / `Builder` stay structurally the same here.
// The Swift Concurrency migration is the `@MainActor` isolation, which
// replaces the old "builders are called on main thread by convention" rule.

@MainActor
public protocol Buildable: AnyObject {}

@MainActor
open class Builder<DependencyType>: Buildable {

	public let dependency: DependencyType

	public init(dependency: DependencyType) {
		self.dependency = dependency
	}
}
