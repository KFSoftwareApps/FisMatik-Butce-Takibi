//
//  FismatikWidgetLiveActivity.swift
//  FismatikWidget
//
//  Created by Squared on 29.12.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FismatikWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FismatikWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FismatikWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FismatikWidgetAttributes {
    fileprivate static var preview: FismatikWidgetAttributes {
        FismatikWidgetAttributes(name: "World")
    }
}

extension FismatikWidgetAttributes.ContentState {
    fileprivate static var smiley: FismatikWidgetAttributes.ContentState {
        FismatikWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FismatikWidgetAttributes.ContentState {
         FismatikWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FismatikWidgetAttributes.preview) {
   FismatikWidgetLiveActivity()
} contentStates: {
    FismatikWidgetAttributes.ContentState.smiley
    FismatikWidgetAttributes.ContentState.starEyes
}
