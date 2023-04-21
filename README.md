## Description

• This GPT iPhone client app features a modern, reactive, unidirectional dataflow architecture, implemented in Combine.

## Notes

• Store.swift (state machine implementation) is adapted from https://obscuredpixels.com/managing-view-state-with-combine

• The chat interface is implemented both in declarative UIKit and SwiftUI to demonostrate integration of both techniques.

• The project intentionally avoids using storyboards because they combine both view and navigation specification, which can become unwieldy in a large app.

• The project introduces an extensible, reactive routing/coordination framework.

• Flow control diagram can be found here: http://tyler.org/iOSCombineGPTApp/FlowControl.png
  
## To-Do

• SwiftUI autoscrolling not working (at least in Xcode 13.2.1 / iOS 15.2)
