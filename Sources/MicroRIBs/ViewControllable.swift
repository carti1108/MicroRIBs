//
//  ViewControllable.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/20/25.
//

import UIKit

public protocol ViewControllable: AnyObject {

	var uiViewController: UIViewController { get }
}

public extension ViewControllable where Self: UIViewController {

	var uiViewController: UIViewController { self }
}

