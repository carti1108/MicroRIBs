//
//  PresentableInteractor.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/23/25.
//

// Migration note:
// RxSwift replacement mapping:
// - No Rx lifecycle type was replaced in this file directly.
// - The migration here is `@MainActor` plus `isolated deinit` so the upstream
//   leak-check call remains actor-safe under Swift 6 strict concurrency.

@MainActor
open class PresentableInteractor<PresentableType>: Interactor {

	public let presenter: PresentableType

	public init(presenter: PresentableType) {
		self.presenter = presenter
		super.init()
	}

	isolated deinit {
		LeakDetector.instance.expectDeallocate(object: self.presenter as AnyObject)
	}
}
