//
//  Executor.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/24/26.
//

import Foundation

/// A utility for executing tasks with a delay, taking frame duration into account.
public class Executor {

	/// Executes the given logic after the specified delay.
	///
	/// - Parameters:
	///   - delay: The delay before executing the logic.
	///   - maxFrameDuration: The maximum allowed duration for a single frame.
	///   - logic: The logic to execute.
	/// - Returns: A task representing the execution.
	public static func execute(withDelay delay: TimeInterval, maxFrameDuration: Int = 33, logic: @escaping @MainActor () -> Void) -> Task<Void, Never> {

		return Task { @MainActor in
			let period = UInt64(maxFrameDuration) * 1_000_000 / 3
			let maxFrameDurationSec = Double(maxFrameDuration) / 1000.0

			var lastRunLoopTime = Date().timeIntervalSinceReferenceDate
			var properFrameTime = 0.0

			while properFrameTime <= delay {
				try? await Task.sleep(nanoseconds: period)

				if Task.isCancelled { return }

				let currentTime = Date().timeIntervalSinceReferenceDate
				let trueElapsedTime = currentTime - lastRunLoopTime
				lastRunLoopTime = currentTime

				let boundedElapsedTime = min(trueElapsedTime, maxFrameDurationSec)
				properFrameTime += boundedElapsedTime
			}

			logic()
		}
	}
}
