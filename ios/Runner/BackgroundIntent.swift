//
//  BackgroundIntent.swift
//  Runner
//
//  App Intent that triggers the Flutter home_widget background callback
//  (widgetInteractiveCallback in Dart) when a widget button is tapped.
//  Add this file's target membership to BOTH Runner and FinanceWidgetExtension.
//

import AppIntents
import Foundation
import home_widget

@available(iOS 17, *)
public struct BackgroundIntent: AppIntent {
  static public var title: LocalizedStringResource = "Finance Quick Add"

  @Parameter(title: "Widget URI")
  var url: URL?

  @Parameter(title: "AppGroup")
  var appGroup: String?

  public init() {}

  public init(url: URL?, appGroup: String?) {
    self.url = url
    self.appGroup = appGroup
  }

  public func perform() async throws -> some IntentResult {
    await HomeWidgetBackgroundWorker.run(url: url, appGroup: appGroup!)
    return .result()
  }
}

/// Allows the interactive button to work even when the app is fully suspended
/// (iOS may briefly bring the app to the foreground to run the callback).
@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension BackgroundIntent: ForegroundContinuableIntent {}
