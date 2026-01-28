//
//  PresentableInteractor.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/23/25.
//

open class PresentableInteractor<PresentableType>: Interactor {

	public let presenter: PresentableType

	public init(presenter: PresentableType) {
		self.presenter = presenter
	}

	deinit {
		LeakDetector.instance.expectDeallocate(object: self.presenter as AnyObject)
	}
}

