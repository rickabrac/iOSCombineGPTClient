## Description

• This GPT client for iOS features a modern, reactive, unidirectional dataflow architecture, implemented in Combine.

## Notes

• Store.swift (state machine) adapted from: https://obscuredpixels.com/managing-view-state-with-combine

• The chat interface is implemented in declarative UIKit and SwiftUI to demonstrate both techniques.

• The project introduces an extensible, reactive routing/coordination framework, implemented in Combine.

• Flow control is described here: http://tyler.org/iOSCombineGPTClient/FlowControl.png

• SwiftUI Views and UIViewControllers are unit-tested via SPM swift-snapshot-testing, in lieu of XCUITest.
  
## To-Do

• SwiftUI autoscrolling not working (in Xcode 13.2.1 / iOS 15.2)
