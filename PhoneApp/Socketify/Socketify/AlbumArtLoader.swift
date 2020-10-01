//
//  AlbumArtLoader.swift
//  Socketify
//
//  Created by Mateus Melchiades on 01/10/20.
//

import Foundation
import Combine
import SwiftUI

class AlbumArtLoader: ObservableObject {
	private var cancellable: AnyCancellable?
	let objectWillChange = PassthroughSubject<UIImage?, Never>()
	
	func load(url: URL) {
		self.cancellable = URLSession.shared
			.dataTaskPublisher(for: url)
			.map({ $0.data })
			.eraseToAnyPublisher()
			.receive(on: RunLoop.main)
			.map({ UIImage(data: $0) })
			.replaceError(with: nil)
			.sink(receiveValue: { image in
				self.objectWillChange.send(image)
			})
	}
	
	func cancel() {
		cancellable?.cancel()
	}
}
