//
//  Workflow.swift
//  MicroRIBs
//
//  Created by Kiseok on 4/9/26.
//

import Foundation

// Migration note:
// RxSwift replacement mapping:
// - `Workflow.onStep { ... -> Observable<(NextActionableItem, Value)> }`
//   -> `Workflow.onStep { ... async throws -> (NextActionableItem, Value) }`
// - `Step.onStep { ... -> Observable<(NextActionableItem, Value)> }`
//   -> `Step.onStep { ... async throws -> (NextActionableItem, Value) }`
// - `PublishSubject<(ActionableItemType, ())>` root trigger -> `subscribe(_:)`
//   starting committed `Task`s directly
// - `CompositeDisposable` owned by the workflow -> `AnyCancelTaskBag`
// - `Disposable.disposeWith(workflow:)` -> `Task.disposeWith(workflow:)`
// - `flatMapLatest + filter + take(1) + share()` step progression
//   -> sequential `async` chaining plus "wait until Interactable is active"

@MainActor
open class Workflow<ActionableItemType> {

	open func didComplete() {
	}

	open func didFork() {
	}

	open func didReceiveError(_ error: Error) {
	}

	public init() {}

	public final func onStep<NextActionableItemType, NextValueType>(
		_ onStep: @escaping @MainActor (ActionableItemType) async throws -> (NextActionableItemType, NextValueType)
	) -> Step<ActionableItemType, NextActionableItemType, NextValueType> {
		Step(workflow: self) { actionableItem in
			try await onStep(actionableItem)
		}
	}

	@discardableResult
	public final func subscribe(_ actionableItem: ActionableItemType) -> Task<Void, Never> {
		guard !commitFactories.isEmpty else {
			assertionFailure("Attempt to subscribe to \(self) before it is committed.")
			let noopTask = Task { }
			noopTask.store(in: cancellables)
			return noopTask
		}

		let workflowTask = Task { @MainActor [weak self] in
			guard let self else { return }

			let tasks = self.commitFactories.map { factory in
				let task = factory(actionableItem)
				task.store(in: self.cancellables)
				return task
			}

			for task in tasks {
				_ = await task.result
			}
		}

		workflowTask.store(in: cancellables)
		return workflowTask
	}

	fileprivate func appendCommit(
		_ factory: @escaping @MainActor (ActionableItemType) -> Task<Void, Never>
	) {
		commitFactories.append(factory)
	}

	fileprivate func didCompleteIfNotYet() {
		guard !didInvokeComplete else { return }
		didInvokeComplete = true
		didComplete()
	}

	fileprivate let cancellables = AnyCancelTaskBag()

	private var didInvokeComplete = false
	private var commitFactories: [@MainActor (ActionableItemType) -> Task<Void, Never>] = []
}

@MainActor
open class Step<WorkflowActionableItemType, ActionableItemType, ValueType> {

	private let workflow: Workflow<WorkflowActionableItemType>
	private var operation: @MainActor (WorkflowActionableItemType) async throws -> (ActionableItemType, ValueType)

	fileprivate init(
		workflow: Workflow<WorkflowActionableItemType>,
		operation: @escaping @MainActor (WorkflowActionableItemType) async throws -> (ActionableItemType, ValueType)
	) {
		self.workflow = workflow
		self.operation = operation
	}

	public final func onStep<NextActionableItemType, NextValueType>(
		_ onStep: @escaping @MainActor (ActionableItemType, ValueType) async throws -> (NextActionableItemType, NextValueType)
	) -> Step<WorkflowActionableItemType, NextActionableItemType, NextValueType> {
		Step<WorkflowActionableItemType, NextActionableItemType, NextValueType>(workflow: workflow) { rootActionableItem in
			let (actionableItem, value) = try await self.operation(rootActionableItem)
			let activeActionableItem = try await Self.awaitActiveIfNeeded(actionableItem)
			return try await onStep(activeActionableItem, value)
		}
	}

	public final func onError(
		_ onError: @escaping @MainActor (Error) -> Void
	) -> Step<WorkflowActionableItemType, ActionableItemType, ValueType> {
		let previousOperation = operation
		operation = { rootActionableItem in
			do {
				return try await previousOperation(rootActionableItem)
			} catch {
				onError(error)
				throw error
			}
		}
		return self
	}

	@discardableResult
	public final func commit() -> Workflow<WorkflowActionableItemType> {
		workflow.appendCommit { [workflow, operation] rootActionableItem in
			Task { @MainActor in
				do {
					_ = try await operation(rootActionableItem)
					workflow.didCompleteIfNotYet()
				} catch is CancellationError {
					return
				} catch WorkflowStepError.actionableItemBecameInactiveBeforeStep {
					return
				} catch {
					workflow.didReceiveError(error)
				}
			}
		}
		return workflow
	}

	public final func fork() -> Step<WorkflowActionableItemType, ActionableItemType, ValueType> {
		workflow.didFork()
		return Step(workflow: workflow, operation: operation)
	}

	private static func awaitActiveIfNeeded(_ actionableItem: ActionableItemType) async throws -> ActionableItemType {
		guard let interactable = actionableItem as? Interactable else {
			return actionableItem
		}

		for await isActive in interactable.isActiveStream {
			if isActive {
				return actionableItem
			}
		}

		throw WorkflowStepError.actionableItemBecameInactiveBeforeStep
	}
}

public extension Task {

	@MainActor
	func disposeWith<ActionableItemType>(workflow: Workflow<ActionableItemType>) {
		store(in: workflow.cancellables)
	}
}

public extension AnyCancellableTask {

	@MainActor
	func disposeWith<ActionableItemType>(workflow: Workflow<ActionableItemType>) {
		workflow.cancellables.insert(self)
	}
}

@MainActor
private enum WorkflowStepError: Error {
	case actionableItemBecameInactiveBeforeStep
}
