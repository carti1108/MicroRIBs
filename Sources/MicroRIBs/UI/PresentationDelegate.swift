//
//  PresentationDelegate.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/30/25.
//

import UIKit

@MainActor
public final class PresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {

	// MARK: - Private Properties

	private let onDismiss: () -> Void
	
	private weak var presentationController: UIPresentationController?
	
	// MARK: - Initialization

	public init(
		onDismiss: @escaping () -> Void,
		presentationController: UIPresentationController
	) {
		self.onDismiss = onDismiss
		self.presentationController = presentationController
		super.init()
		presentationController.delegate = self
	}
	
	// MARK: - Public Methods

	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		self.onDismiss()
	}
}

