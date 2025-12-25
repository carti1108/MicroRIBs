//
//  Component.swift
//  Architecture
//
//  Created by Kiseok on 12/20/25.
//

open class Component<DependencyType>: Dependency {

	public let dependency: DependencyType

	public init(dependency: DependencyType) {
		self.dependency = dependency
	}
}
