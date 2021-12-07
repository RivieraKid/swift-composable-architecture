import Combine
import ComposableArchitecture
import XCTest

@testable import SwiftUICaseStudies

class LongLivingEffectsTests: XCTestCase {
  func testReducer() {
    // A passthrough subject to simulate the screenshot notification
    let screenshotTaken = PassthroughSubject<Void, Never>()

    let store = TestStore(
      initialState: .init(),
      reducer: longLivingEffectsReducer,
      environment: .init(
        userDidTakeScreenshot: Effect(screenshotTaken)
      )
    )

    store.send(.onAppear)

    // Simulate a screenshot being taken
    screenshotTaken.send()
    store.receive(.userDidTakeScreenshotNotification) {
      $0.screenshotCount = 1
    }

    store.send(.onDisappear)

    // Simulate a screenshot being taken to show no effects
    // are executed.
    screenshotTaken.send()
  }

  @MainActor
  func testNew() async {
    // A passthrough subject to simulate the screenshot notification
    let screenshotTaken = PassthroughSubject<Void, Never>()

    let store = MainActorTestStore(
      initialState: .init(),
      reducer: longLivingEffectsReducer,
      environment: .init(
        userDidTakeScreenshot: Effect(screenshotTaken)
      )
    )

    let task = store.send(.onAppear)

    // Simulate a screenshot being taken
    screenshotTaken.send()
    await store.receive(.userDidTakeScreenshotNotification) {
      $0.screenshotCount = 1
    }
    screenshotTaken.send()
    await store.receive(.userDidTakeScreenshotNotification) {
      $0.screenshotCount = 2
    }

    task.cancel()
    await task.value
    // await task.cancelAndFoo()
    // await task.cancel()
    // await store.cancel(task: task)
    // await store.completed(task: task)
  }

  @MainActor
  func testAsync() async {
    enum Action: Equatable {
      case tap, response(Int)
    }
    let store = MainActorTestStore<Int, Action, Void>(
      initialState: 0,
      reducer: .init { state, action, _ in
        switch action {
        case .tap:
          return Effect.task {
            await Task.sleep(100 * NSEC_PER_MSEC)
            return .response(42)
          }
        case let .response(number):
          state = number
          return .none
        }
      },
      environment: ()
    )

    store.send(.tap)

    await store.receive(.response(42)) {
      $0 = 42
    }
  }
}
