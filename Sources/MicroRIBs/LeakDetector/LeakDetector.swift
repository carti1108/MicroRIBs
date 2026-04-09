//
//  LeakDetector.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/24/25.
//
//
// Migration note:
// RxSwift replacement mapping:
// - `var status: Observable<LeakDetectionStatus>` -> `var status: AsyncStream<LeakDetectionStatus>`
// - `BehaviorRelay<Int>(value: 0)` for `expectationCount`
//   -> `CurrentValueAsyncStream<Int>(0)`
// - `expectationCount.accept(newValue)` -> `expectationCount.send(newValue)`
// - `expectationCount.asObservable().map(...).distinctUntilChanged()`
//   -> `expectationCount.stream.map(...).removeDuplicates().eraseToStream()`
// - `BehaviorRelay<Bool>(value: false)` inside `LeakDetectionHandleImpl`
//   -> `CurrentValueAsyncStream<Bool>(false)`
// - `cancelledRelay.accept(true)` -> `cancelledStream.send(true)`
// - `Executor.execute(withDelay:) { ... }` still exists, but now returns a
//   Swift Concurrency `Task<Void, Never>` instead of an Rx-managed resource.

import UIKit
import AsyncAlgorithms

public enum LeakDetectionStatus {
	case InProgress
	case DidComplete
}

public struct LeakDefaultExpectationTime {
	public static let deallocation = 1.0
	public static let viewDisappear = 5.0
}

public protocol LeakDetectionHandle {
	func cancel()
}

@MainActor
public class LeakDetector {

	public static private(set) var instance = LeakDetector()

	static func setInstance(_ newInstance: LeakDetector) {
		instance = newInstance
	}

	public var status: AsyncStream<LeakDetectionStatus> {
		return expectationCount.stream
			.map { count in
				count > 0 ? LeakDetectionStatus.InProgress : LeakDetectionStatus.DidComplete
			}
			.removeDuplicates()
			.eraseToStream()
	}

	@discardableResult
	public func expectDeallocate(object: AnyObject, inTime time: TimeInterval = LeakDefaultExpectationTime.deallocation) -> LeakDetectionHandle {
		self.increaseExpectationCount()

		let objectDescription = String(describing: object)
		let objectId = String(ObjectIdentifier(object).hashValue) as NSString
		
		lock.lock()
		trackingObjects.setObject(object, forKey: objectId)
		lock.unlock()

		let handle = LeakDetectionHandleImpl { [weak self] in
			self?.decreaseExpectationCount()
		}

		_ = Executor.execute(withDelay: time) { [weak self] in
			guard let self = self else { return }

			if !handle.cancelled {
				self.lock.lock()
				let didDeallocate = (self.trackingObjects.object(forKey: objectId) == nil)
				let trackingObjectsDescription = String(describing: self.trackingObjects)
				self.lock.unlock()
				
				let message = "<\(objectDescription): \(objectId)> has leaked. Objects are expected to be deallocated at this time: \(trackingObjectsDescription)"

				if self.disableLeakDetector {
					if !didDeallocate {
						print("Leak detection is disabled. This should only be used for debugging purposes.")
						print(message)
					}
				} else {
					assert(didDeallocate, message)
				}
			}

			if !handle.cancelled {
				self.decreaseExpectationCount()
			}
		}

		return handle
	}

	@discardableResult
	public func expectViewControllerDisappear(viewController: UIViewController, inTime time: TimeInterval = LeakDefaultExpectationTime.viewDisappear) -> LeakDetectionHandle {
		self.increaseExpectationCount()

		let handle = LeakDetectionHandleImpl { [weak self] in
			self?.decreaseExpectationCount()
		}

		_ = Executor.execute(withDelay: time) { [weak self, weak viewController] in
			guard let self = self else { return }

			if let viewController = viewController, !handle.cancelled {
				let viewDidDisappear = (!viewController.isViewLoaded || viewController.view.window == nil)
				
				self.lock.lock()
				let trackingObjectsDescription = String(describing: self.trackingObjects)
				self.lock.unlock()
				
				let message = "\(viewController) appearance has leaked. Either its parent router who does not own a view controller was detached, but failed to dismiss the leaked view controller; or the view controller is reused and re-added to window, yet the router is not re-attached but re-created. Objects are expected to be deallocated at this time: \(trackingObjectsDescription)"

				if self.disableLeakDetector {
					if !viewDidDisappear {
						print("Leak detection is disabled. This should only be used for debugging purposes.")
						print(message)
					}
				} else {
					assert(viewDidDisappear, message)
				}
			}

			if !handle.cancelled {
				self.decreaseExpectationCount()
			}
		}

		return handle
	}

	static var disableLeakDetectorOverride: Bool = false

#if DEBUG
	func reset() {
		lock.lock()
		trackingObjects.removeAllObjects()
		lock.unlock()
		expectationCount.send(0)
	}
#endif

	private let expectationCount = CurrentValueAsyncStream<Int>(0)
	private let lock = NSLock()
	private let trackingObjects = NSMapTable<AnyObject, AnyObject>.strongToWeakObjects()

	private func increaseExpectationCount() {
		expectationCount.send(expectationCount.value + 1)
	}

	private func decreaseExpectationCount() {
		expectationCount.send(expectationCount.value - 1)
	}

	lazy var disableLeakDetector: Bool = {
		if let environmentValue = ProcessInfo().environment["DISABLE_LEAK_DETECTION"] {
			let lowercase = environmentValue.lowercased()
			return lowercase == "yes" || lowercase == "true"
		}
		return LeakDetector.disableLeakDetectorOverride
	}()
}

private class LeakDetectionHandleImpl: LeakDetectionHandle {
	var cancelled: Bool {
		return cancelledStream.value
	}

	let cancelledStream = CurrentValueAsyncStream<Bool>(false)
	let cancelClosure: (() -> Void)?

	init(cancelClosure: (() -> Void)? = nil) {
		self.cancelClosure = cancelClosure
	}

	func cancel() {
		cancelledStream.send(true)
		cancelClosure?()
	}
}
