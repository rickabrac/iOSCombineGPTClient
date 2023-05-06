//
//  ShareViewController.swift
//  CombineGPTClientShare
//
//  Created by Rick Tyler on 5/2/23.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: UIViewController {
	private let typeImage = String(kUTTypeImage)
	private var appURLString = "combinegptclient://image?url="
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
			let itemProvider = extensionItem.attachments?.first else {
				self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
				return
		}
		if itemProvider.hasItemConformingToTypeIdentifier(typeImage) {
			importImage(itemProvider: itemProvider)
		} else {
			print("Error: No image received")
			self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
		}
	}
	
	private func importImage(itemProvider: NSItemProvider) {
		itemProvider.loadItem(forTypeIdentifier: typeImage, options: nil) { (item, error) in
			if let error = error {
				print("Text-Error: \(error.localizedDescription)")
			}
			if let url = item as? URL, let nsUrl = item as? NSURL, let urlString = nsUrl.absoluteString {
				self.appURLString += urlString
				do {
					let imageData = try Data(contentsOf: url)
					guard let defaults = UserDefaults(suiteName: "group.gptclient") else {
						fatalError("importImage: failed to open defaults for suiteName \"gptclient\"")
					}
					defaults.set(imageData, forKey: "imageData")
				} catch {
					print("Error loading image : \(error)")
				}
			}
			self.extensionContext?.completeRequest(returningItems: nil, completionHandler: { _ in
				guard let url = URL(string: self.appURLString) else { return }
				_ = self.openURL(url)
			})
		}
	}
	
	@objc func openURL(_ url: URL) -> Bool {
		var responder: UIResponder? = self
		while responder != nil {
			if let application = responder as? UIApplication {
				return application.perform(#selector(openURL(_:)), with: url) != nil
			}
			responder = responder?.next
		}
		return false
	}
}
