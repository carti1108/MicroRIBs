//
//  LeakDetector.swift
//  MicroRIBs
//
//  Created by Kiseok on 12/24/25.
//
//
//  Migration Guide (RxSwift -> Swift Concurrency):
//
//  1. Observable<LeakDetectionStatus> -> AsyncStream<LeakDetectionStatus>
//     - 기존 Rx의 BehaviorSubject와 distinctUntilChanged 로직을 대체하기 위해
//       내부적으로 [UUID: AsyncStream.Continuation] 딕셔너리를 사용하여
//       상태가 변경될 때마다 모든 구독자에게 값을 전달하는 Multicast 패턴을 구현했습니다.
//
//  2. BehaviorRelay<Int> -> Int (Property Observer)
//     - expectationCount 변수의 didSet 블록에서 상태 변화를 감지하고
//       subscribers 딕셔너리를 순회하며 변경된 상태를 Broadcast 합니다.
//
//  3. LeakDetectionHandleImpl (RxRelay) -> LeakDetectionHandleImpl (Task)
//     - 취소 상태를 RxRelay로 관리하던 것을, Task.cancel() 호출과
//       CompletionState 클래스를 이용한 동기화 로직으로 변경했습니다.
//
//  4. Executor.execute -> Task return
//     - 실행 취소를 위해 Executor가 반환하는 Task 객체를 Handle이 보유하도록 변경했습니다.
//

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
