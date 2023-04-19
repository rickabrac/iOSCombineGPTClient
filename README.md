## Description

This app uses unidirectional data flow to manage state and is implemented with Combine.

• State machine (Store.swift) adapted from https://obscuredpixels.com/managing-view-state-with-combineo

## Files

FluxGPTChat/

   APIKeyUIView.swift          SwiftUI View that prompts for an API Key if needed
ChatAPI.swift               GPT3 API Service
ChatRouter.swift            subclass of Router that coordinates ChatTabView
ChatStore.swift             single source of truth for a chat interface
ChatTabUIView.swift         SwiftUI tab view that allows user to switch interfaces
ChatUIView.swift            SwiftUI version of the chat interface
  ChatViewController.swift    declarative UIKit version of chat intervace
  Common.swift                shared Protocols, Extensions, etc.
  MainRouter.swift            subclass of Router that acts as the app entry point
  Router.swift                base class for state-drive routers (in lieu of traditional coordination)
  SplashUIView.swift          SwiftUI welcome screen splash screen
  Store.swift                 Combine-based Flux store implementation
  TestResponse.json           Canned response used by MockChatAPI.swift in tests
  
FluxGPTChatTests/

  ChatStoreTests.swift       ChatStore unit tests
  ChatUIViewTests.swift      ChatUIView snapshot tests
  ChatViewControllerTests    ChatViewController snapshot tests
  MockChatAPI.swift          Mock version of ChatAPI for testing
  
## To-Do

• SwiftUI autoscrolling not working (at least in Xcode 13.2.1 / iOS 15.2)


