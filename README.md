## Description

• GPT iOS client app featuring a modern, reactive, unidirectional dataflow architecture, implemented in Combine.

## Notes

• Store.swift (state machine implementation) is adapted from https://obscuredpixels.com/managing-view-state-with-combine

• The chat interface is implemented in both declarative UIKit and SwiftUI to demonostrate integration of both techniques.

• The project intentionally omits storyboards because they combine view and navigation specification, which I avoid.

• The project introduces an extensible, reactive routing/coordination framework.

• Flow control diagram is here: http://tyler.org/iOSCombineGPTApp/FlowControl.png
  
## To-Do

• SwiftUI autoscrolling not working (at least in Xcode 13.2.1 / iOS 15.2)
