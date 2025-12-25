//
//  LeakDetector.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/24/25.
//

import UIKit

@MainActor
public class LeakDetector {

	public static let instance = LeakDetector()

	private init() {}

	public func expectDeallocate(object: AnyObject, in delay: TimeInterval = 1.0) {
			#if DEBUG
			weak var weakObject = object

			DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
				if let leakedObject = weakObject {
					print("🚨 [LeakDetector] Memory Leak Detected!")
					print("   Object: \(leakedObject)")
					print("   Type: \(type(of: leakedObject))")

					assertionFailure("🚨 Memory Leak: \(type(of: leakedObject)) did not deallocate.")
				} else {
					print("✅ [LeakDetector] Deallocated: \(type(of: object))")
				}
			}
			#endif
		}

	public func expectViewControllerDisappear(viewController: UIViewController, in delay: TimeInterval = 2.0) {
			#if DEBUG
			weak var weakVC = viewController

			DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
				guard let vc = weakVC else { return }

				if vc.isViewLoaded && vc.view.window != nil {
					 print("🚨 [LeakDetector] ViewController Leak Detected!")
					 print("   VC: \(vc)")
					 assertionFailure("🚨 ViewController Leak: \(type(of: vc)) is still on window.")
				}
			}
			#endif
		}
}

