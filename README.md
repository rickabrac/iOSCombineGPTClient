## Description

• GPT iOS client app featuring a modern, reactive, unidirectional dataflow architecture, implemented in Combine.

## Notes

• Store.swift (state machine implementation) is adapted from https://obscuredpixels.com/managing-view-state-with-combine

• The chat user interface is implemented both in declarative UIKit and SwiftUI to demonostrate integration of both techniques.

• The project intentionally does not use storyboards because they combine view and navigation specifications, which I would avoid.

• The project introduces an extensible, reactive routing/coordination framework

• This diagram shows the app's control flow: http://tyler.org/iOSCombineGPTApp/FlowControl.png
  
## To-Do

• SwiftUI autoscrolling not working (at least in Xcode 13.2.1 / iOS 15.2)
