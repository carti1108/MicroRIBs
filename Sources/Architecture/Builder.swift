//
//  Builder.swift
//  Architecture
//
//  Created by Kiseok on 12/20/25.
//

public protocol Buildable: AnyObject {}

open class Builder<DependencyType>: Buildable {

	public let dependency: DependencyType

	public init(dependency: DependencyType) {
		self.dependency = dependency
	}
}
