## Description

• This GPT iPhone client app features a modern, reactive, unidirectional dataflow architecture, implemented in Combine.

## Notes

• Store.swift (state machine implementation) is adapted from https://obscuredpixels.com/managing-view-state-with-combine

• Chat interface is implemented in declarative UIKit and SwiftUI to demonostrate integration of both popular techniques.

• The project does not use storyboards because they combine view and navigation specification, which is unwieldy in large apps.

• The project introduces my extensible, reactive routing/coordination framework.

• Flow control is described here: http://tyler.org/iOSCombineGPTApp/FlowControl.pngo

• SwiftUI Views and UIViewControllers are tested using swift-snapshot-testing from Swift Package Manager.
  
## To-Do

• SwiftUI autoscrolling not working (at least in Xcode 13.2.1 / iOS 15.2)
