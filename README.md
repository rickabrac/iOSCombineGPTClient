## Description

• This GPT client app for iOS features a modern, reactive, unidirectional dataflow architecture, implemented in Combine.

## Notes

• Store.swift (state machine implementation) is adapted from https://obscuredpixels.com/managing-view-state-with-combine.

• The chat interface is implemented in declarative UIKit and SwiftUI to demonstrate integration of both techniques.

• The project does not use storyboards because they combine view and navigation specification, which is unwieldy in large apps.

• The project introduces an extensible, reactive routing/coordination framework, also implemented in Combine.

• Flow control is described here: http://tyler.org/iOSCombineGPTClient/FlowControl.png

• SwiftUI Views and UIViewControllers are tested using swift-snapshot-testing via the Swift Package Manager.
  
## To-Do

• SwiftUI autoscrolling not working (at least in Xcode 13.2.1 / iOS 15.2)
