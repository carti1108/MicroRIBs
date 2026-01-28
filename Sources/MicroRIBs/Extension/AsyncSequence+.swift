//
//  AsyncSequence+.swift
//  MicroRIBs
//
//  Created by Kiseok on 1/26/26.
//

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
