//
//  ChatViewController.swift
//  FluxGPTChat
//  Copyright 2023 Rick Tyler
//  SPDX-License-Identifier: MIT
//
//  Declarative UIKit version of the chat interface

import UIKit
import Combine
import SwiftUI

class ChatViewController: UIViewController {
	typealias StoreState = ChatState
	typealias StoreAction = ChatAction
	
	private var router: ChatRouter?
	private var chat: ChatStore? = nil
	private var store: ChatStoreType? = nil
	private let myTitle = UILabel()
	private let prompt = MyTextField()
	private let clearButton = UIButton(type: .system)
	private let response = UITextView()
	private let spinner = UIActivityIndicatorView(style: .medium)
	private let shareButton = UIButton(type: .system)
	
	init(router: ChatRouter) {
		self.router = router
		super.init(nibName: nil, bundle: nil)
	}

	func setChatStore(_ chat: ChatStore) {
		self.chat = chat
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.router = nil
	}
	
	func overrideUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
		self.overrideUserInterfaceStyle = style
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configure()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
		myTitle.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		prompt.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		response.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
	}
	
	@objc func clearTextField() {
		prompt.text = ""
		prompt.rightViewMode = .never
	}
	
	func configure() {
		
		if chat == nil {
			chat = ChatStore()
		}
		
		store = chat?.store
		
		guard let store = store else {
			fatalError("ChatViewController.configure: failed to unwrap store")
		}
		
		Task {
			await store.bindStateObserver(refreshView, &ChatViewController.pool)
		}
		
		view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
		
		// title
		myTitle.text = "UIKit GPT Chat"
		myTitle.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
		myTitle.textAlignment = .center
		myTitle.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		view.addSubview(myTitle)
		myTitle.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			myTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
			myTitle.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
			myTitle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
			myTitle.heightAnchor.constraint(equalToConstant: 32)
		])
		
		// share button
		let width = 24.0
		let height = 1.09 * width
		shareButton.setBackgroundImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
		shareButton.addAction(UIAction(handler: { button in
			self.spinner.isHidden = false
			guard let response = self.store?.state.response else { return }
			let activityViewController = UIActivityViewController(activityItems: [response], applicationActivities: nil)
			activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
			activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
			self.present(activityViewController, animated: true, completion: nil)
			Task {
				self.spinner.isHidden = true
			}
		}), for: .touchDown)
		view.addSubview(shareButton)
		view.bringSubviewToFront(shareButton)
		shareButton.translatesAutoresizingMaskIntoConstraints = false
		shareButton.isHidden = true
		NSLayoutConstraint.activate([
			shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
			shareButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40.5),
			shareButton.widthAnchor.constraint(equalToConstant: width),
			shareButton.heightAnchor.constraint(equalToConstant: height)
		])
		
		// search field
		prompt.placeholder = "Ask me anything"
		prompt.delegate = self
		prompt.layer.cornerRadius = 5.0
		prompt.autocapitalizationType = .none
		prompt.font = UIFont.systemFont(ofSize: 15.0)
		prompt.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		prompt.clearButtonMode = .always
		prompt.borderStyle = .roundedRect
		prompt.layer.cornerRadius = 8
		prompt.layer.borderWidth = 1
		prompt.layer.borderColor = UIColor.lightGray.cgColor
		let leftView = UIView(frame: CGRect(x: 0, y:0, width: 7, height: prompt.frame.size.height))
		leftView.backgroundColor = prompt.backgroundColor;
		prompt.leftView = leftView
		prompt.leftViewMode = .always
		view.addSubview(prompt)
		prompt.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			prompt.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
			prompt.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
			prompt.topAnchor.constraint(equalTo: myTitle.bottomAnchor, constant: 3.5),
			prompt.heightAnchor.constraint(equalToConstant: 43)
		])

		// The UITextField clear button does not not appear to work in my version of Xcode (13.2.1)
		// presented from a SwiftUI view. This is my workaround, deprecation warnings and all.
		
		let clearButton = UIButton(type: .system)
		clearButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
		clearButton.setTitle("", for: .normal)
		clearButton.setImage(UIImage(systemName: "multiply.circle.fill")!, for: .normal)
		clearButton.isUserInteractionEnabled = true
		prompt.addSubview(clearButton)
		clearButton.tintColor = .gray // .lightGray
		clearButton.addTarget(self, action: #selector(clearTextField), for: .touchDown)
		prompt.rightView = clearButton
		prompt.rightViewMode = .never
		clearButton.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			clearButton.topAnchor.constraint(equalTo: prompt.topAnchor, constant: 8),
			clearButton.trailingAnchor.constraint(equalTo: prompt.trailingAnchor, constant: -30),
			clearButton.widthAnchor.constraint(equalToConstant: 23),
			clearButton.heightAnchor.constraint(equalToConstant: 17.5)
		])
		
		// response
		response.isEditable = false
		view.addSubview(response)
		response.sizeToFit()
		response.translatesAutoresizingMaskIntoConstraints = false
		response.contentInset = UIEdgeInsets(top: 6.5, left: 0, bottom: 0, right: 0)
		NSLayoutConstraint.activate([
			response.topAnchor.constraint(equalTo: prompt.bottomAnchor, constant: 0),
			response.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
			response.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
			response.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5)
		])
		
		// activity indicator
		spinner.center = view.center
		spinner.startAnimating()
		view.addSubview(spinner)
		spinner.isHidden = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		Task {
			self.prompt.becomeFirstResponder()
		}
	}
	
	func presentErrorAlert(completion: (() -> ())? = nil) {
		guard let store = store else {
			fatalError("ChatViewController.presentErrorAlert: failed to unwrap store")
		}
		let alert = UIAlertController(title: "Fetch Error", message: "\n\(store.state.error)", preferredStyle: .alert)
		let dismiss = UIAlertAction(title: "OK", style: .default) { UIAlertAction in }
		alert.addAction(dismiss)
		self.present(alert, animated: true, completion: nil)
	}

	private func refreshView() {
		prompt.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		guard let store = store else {
			fatalError("ChatViewController.refreshView: failed to unwrap store")
		}
		spinner.color = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
		if store.state.error.count > 0 {
			presentErrorAlert()
		}
		let attributedString = NSMutableAttributedString(string: store.state.response)
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineSpacing = 5
		let range = NSMakeRange(0, attributedString.length)
		attributedString.addAttribute(
			NSAttributedString.Key.paragraphStyle,
			value: paragraphStyle,
			range: range
		)
		attributedString.addAttribute(
			NSAttributedString.Key.foregroundColor,
			value: traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black,
			range: range
		)
		let attributes: [NSAttributedString.Key: Any] = [ .font: UIFont.systemFont(ofSize: 15) ]
		attributedString.addAttributes(attributes, range: range) // NSMakeRange(0, attributedString.length))
		response.attributedText = attributedString
		let scrollOffset = response.contentSize.height - response.frame.size.height
		if scrollOffset > 0 {
			response.setContentOffset(CGPoint(x: 0, y: scrollOffset), animated: true)
		}
		guard let stream = store.state.stream else {
			if store.state.response.count > 0 {
				shareButton.isHidden = false
			}
			return
		}
		if prompt.text?.count == 0, store.state.prompt.count > 0 {
			prompt.text = store.state.prompt
		}
		shareButton.isHidden = true
		spinner.isHidden = true
		Task {
			await store.dispatch(action: .streamResponse(stream, store.state.response))
		}
		if store.state.error.count > 0,
		   store.state.isShowingError == false {
			Task {
				await store.dispatch(action: .presentError)
			}
		}
	}

	private class MyTextField: UITextField {
		var textPadding = UIEdgeInsets(
			top: 0,
			left: -4,
			bottom: 0,
			right: -4
		)

		override func textRect(forBounds bounds: CGRect) -> CGRect {
			let rect = super.textRect(forBounds: bounds)
			return rect.inset(by: textPadding)
		}

		override func editingRect(forBounds bounds: CGRect) -> CGRect {
			let rect = super.editingRect(forBounds: bounds)
			return rect.inset(by: textPadding)
		}
	}
}

// MARK: UITextFieldDelegate conformance

extension ChatViewController: UITextFieldDelegate {

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if string == "", textField.text?.count == 1 {
			prompt.rightViewMode = .never
		} else {
			prompt.rightViewMode = .always
		}
		clearButton.setNeedsDisplay()
		return true
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let chat = chat else {
			fatalError("ChatViewController.textFieldShouldReturn: chat (store) is undefined")
		}
		guard chat.store.state.stream == nil, prompt.text != "" else { return false }
		guard let prompt = textField.text else { return false }
		spinner.isHidden = false
		response.text = ""
		Task {
			if chat.store.state.api == nil {
				guard let key = UserDefaults.standard.object(forKey: ChatAPI.apiKeyDefaultsName) as? String else {
					fatalError("ChatViewController.textFieldShouldReturn: failed to unwrap api key")
				}
				await chat.store.dispatch(action: .setAPI(ChatAPI(key: key)))
			}
			guard let api = chat.store.state.api else {
				fatalError("ChatViewController.textFieldShouldReturn: failed to unwrap api")
			}
			let stream = try! await api.fetchResponseStream(prompt: prompt, store: chat.store)
			await chat.store.dispatch(action: .setPrompt(prompt))
			await chat.store.dispatch(action: .setStream(stream))
			await chat.store.dispatch(action: .streamResponse(stream, ""))
		}
		textField.resignFirstResponder()
		return true
	}

	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
}

//  MARK: UIViewControllerRepresentable wrapper

struct ChatViewControllerUIView : UIViewControllerRepresentable {
	typealias UIViewControllerType = ChatViewController
	var router: ChatRouter
	var chat: ChatStoreType
	public func makeUIViewController(context: UIViewControllerRepresentableContext<ChatViewControllerUIView>) -> ChatViewController {
		return ChatViewController(router: router)
	}
	func updateUIViewController(_ uiViewController: ChatViewController, context: UIViewControllerRepresentableContext<ChatViewControllerUIView>) { }
}
