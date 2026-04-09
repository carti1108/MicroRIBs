//
//  AsyncSequence+.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

// Migration note:
// RxSwift replacement mapping:
// - `Observable<Element>` chains that ended with another `Observable<Element>`
//   are represented here as `AsyncSequence<Element>` chains that are converted
//   back to `AsyncStream<Element>` via `eraseToStream()`.

import Foundation

extension AsyncSequence  {
	func eraseToStream() -> AsyncStream<Element> {
		AsyncStream { continuation in
			let task = Task {
				do {
					for try await element in self {
						continuation.yield(element)
					}

					continuation.finish()
				} catch {
					continuation.finish()
				}
			}
			continuation.onTermination = { _ in task.cancel() }
		}
	}
}
