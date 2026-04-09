//
//  NavigationControllable.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/2/26.
//

import UIKit

@MainActor
public final class NavigationControllerable: ViewControllable {

	// MARK: - Public Properties

	public var uiViewController: UIViewController { self.navigationController }

	public let navigationController: UINavigationController

	// MARK: - Initialization

	@MainActor
	public init(root: ViewControllable) {
		let navigation = UINavigationController(rootViewController: root.uiViewController)
		navigation.navigationBar.isTranslucent = false
		navigation.navigationBar.backgroundColor = .white
		navigation.navigationBar.scrollEdgeAppearance = navigation.navigationBar.standardAppearance

		self.navigationController = navigation
	}
}
