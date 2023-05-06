//
//  Controller.swift
//  CombineGPTClient
//  Created by Rick Tyler
//  SPDX-License-Identifier: MIT

import UIKit
import Combine
import SwiftUI

class ImageViewController: UIViewController, UIGestureRecognizerDelegate {
	typealias StoreState = ChatState
	typealias StoreAction = ChatAction
	
	private var router: ChatRouter?
	private var chat: ChatStore? = nil
	private var store: ChatStoreType? = nil
	private let myTitle = UILabel()
	private let prompt = MyTextField()
	private let clearButton = UIButton(type: .system)
	private let imageView = UIImageView()
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
		let defaults = UserDefaults(suiteName: "group.gptclient")
		if let imageData = defaults?.object(forKey: "imageData") as? Data,
		   let image = UIImage(data: imageData) {
			self.imageView.image = image
		}
		defaults?.removeObject(forKey: "imageData")
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
			fatalError("ImageViewController.configure: failed to unwrap store")
		}
		
		Task {
			await store.bindStateObserver(refreshView, &ImageViewController.pool)
		}
		
		view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
		
		// title
		myTitle.text = "DALL-E Imagemaker (UIKit)"
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
		prompt.placeholder = "Describe an image you want me to generate"
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
		prompt.clearButtonMode = .always
		view.addSubview(prompt)
		prompt.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			prompt.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
			prompt.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
			prompt.topAnchor.constraint(equalTo: myTitle.bottomAnchor, constant: 3.5),
			prompt.heightAnchor.constraint(equalToConstant: 43)
		])
		
		// required to make
		let enableClearButton = UITapGestureRecognizer(target: self, action: nil)
		enableClearButton.delegate =  self;
		enableClearButton.cancelsTouchesInView = false;
		prompt.addGestureRecognizer(enableClearButton)
		
		// imageView
		view.addSubview(imageView)
		imageView.layer.borderWidth = 1
		imageView.center = view.center
		imageView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: -1),
			imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 1),
			imageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -50)
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
			fatalError("ImageViewController.presentErrorAlert: failed to unwrap store")
		}
		let alert = UIAlertController(title: "Fetch Error", message: "\n\(store.state.error)", preferredStyle: .alert)
		let dismiss = UIAlertAction(title: "OK", style: .default) { UIAlertAction in }
		alert.addAction(dismiss)
		self.present(alert, animated: true, completion: nil)
	}

	private func refreshView() {
		prompt.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		guard let store = store else {
			fatalError("ImageViewController.refreshView: failed to unwrap store")
		}
		spinner.color = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
		if !store.state.error.isEmpty {
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
//		response.attributedText = attributedString
//		let scrollOffset = response.contentSize.height - response.frame.size.height
//		if scrollOffset > 0 {
//			response.setContentOffset(CGPoint(x: 0, y: scrollOffset), animated: true)
//		}
//		guard let stream = store.state.stream else {
//			if !store.state.response.isEmpty {
//				shareButton.isHidden = false
//			}
//			return
//		}
//		if prompt.text?.isEmpty != nil, !store.state.prompt.isEmpty {
//			prompt.text = store.state.prompt
//		}
//		shareButton.isHidden = true
//		spinner.isHidden = true
//		Task {
//			await store.dispatch(action: .streamResponse(stream, store.state.response))
//		}
//		if !store.state.error.isEmpty,
//		   store.state.isShowingError == false {
//			Task {
//				await store.dispatch(action: .presentError)
//			}
//		}
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

extension ImageViewController: UITextFieldDelegate {

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if string == "", textField.text?.isEmpty != nil {
			prompt.rightViewMode = .never
		} else {
			prompt.rightViewMode = .always
		}
		clearButton.setNeedsDisplay()
		return true
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let chat = chat else {
			fatalError("ImageViewController.textFieldShouldReturn: chat (store) is undefined")
		}
		guard chat.store.state.stream == nil, prompt.text != "" else { return false }
		guard let prompt = textField.text else { return false }
		spinner.isHidden = false
		DispatchQueue.main.async {
			guard let apiKey = UserDefaults.standard.object(forKey: "GPT3_API_KEY") as? String else {
				fatalError("ImageViewController.textFieldShouldReturn: GPT3_API_KEY undefined")
			}
			let api = ImageGenAPI(key: apiKey)
			api.fetchImage(prompt: prompt, store: chat.store) { (urlString, error) in
				guard urlString.isEmpty == false else {
					DispatchQueue.main.async {
						self.spinner.isHidden = true
						self.prompt.becomeFirstResponder()
					}
					return
				}
				let url = URL(string: urlString)
				let data = try? Data(contentsOf: url!)
				DispatchQueue.main.async {
					print("\(urlString)")
					self.imageView.image = UIImage(data: data!)
					self.spinner.isHidden = true
					self.prompt.becomeFirstResponder()
				}
			}
		}
		textField.resignFirstResponder()
		return true
	}

	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
}

//  MARK: UIViewControllerRepresentable wrapper

struct ImageSwiftUIViewController : UIViewControllerRepresentable {
	typealias UIViewControllerType = ImageViewController
	var router: ChatRouter
	var chat: ChatStoreType
	public func makeUIViewController(context: UIViewControllerRepresentableContext<ImageSwiftUIViewController>) -> ImageViewController {
		return ImageViewController(router: router)
	}
	func updateUIViewController(_ uiViewController: ImageViewController, context: UIViewControllerRepresentableContext<ImageSwiftUIViewController>) { }
}

