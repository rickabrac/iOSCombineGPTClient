# iOS GPT Chat client using the Flux Architecture

## Description

This app uses unidirectional data flow to manage state and is implemented in Combine.

• State machine (Store.swift) adapted from this article: https://obscuredpixels.com/managing-view-state-with-combine

## Bugs (Xcode 13.2.1)

• SwiftUI autoscrolling not working
• Combine-based Router is still a work in progress.

## Modules (Frameworks)

• GPTCore (GPTAPI, Store, Extensions, Protocols, MainCoordinator, AppDelegate, SceneDelegate, Assets, Info, Splash)
• GPTChat (ChatAPI, ChatStore, Chat*View*)
• GPTImage (ImageStore, Image*View*)
