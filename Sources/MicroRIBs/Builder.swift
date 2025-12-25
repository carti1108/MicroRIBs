//
//  Builder.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

@MainActor
public protocol Buildable: AnyObject {}

@MainActor
open class Builder<DependencyType>: Buildable {

	public let dependency: DependencyType

	public init(dependency: DependencyType) {
		self.dependency = dependency
	}
}

