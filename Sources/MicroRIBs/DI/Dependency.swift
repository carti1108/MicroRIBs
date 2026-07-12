//
//  Dependency.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// RxSwift replacement mapping:
// Uber RIBs `Dependency` protocols are kept as-is, but isolated to the main
// actor so dependency resolution matches the framework's main-thread-only model.

/// The base protocol for all dependencies.
@MainActor
public protocol Dependency: AnyObject {}

/// The base protocol for an empty dependency.
@MainActor
public protocol EmptyDependency: Dependency {}
