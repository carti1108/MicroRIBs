//
//  Dependency.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

// Migration note:
// Uber RIBs `Dependency` protocols are kept as-is, but isolated to the main
// actor so dependency resolution matches the framework's main-thread-only model.

@MainActor
public protocol Dependency: AnyObject {}

@MainActor
public protocol EmptyDependency: Dependency {}
