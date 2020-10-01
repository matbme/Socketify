//
//  ContentView.swift
//  Socketify
//
//  Created by Mateus Melchiades on 26/09/20.
//

import SwiftUI
import SwiftSocket
import Combine
import UIKit
import CoreImage

struct ContentView: View {
	let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
	let artLoader = AlbumArtLoader()
	
	@State private var client = TCPClient(address: "192.168.0.15", port: 8888)
	
	@State private var nowPlaying: String = ""
	@State private var artist: String = ""
	@State private var playbackStatus: Image = Image(systemName: "icloud.slash")
	
	@State private var artURL: String = ""
	@State var image: UIImage? = nil
	
    var body: some View {
		ZStack {
			LinearGradient(gradient: Gradient(colors: [.white, .red, .red]), startPoint: .top, endPoint: .bottom)
			
			VStack {
				if let image = image {
					Image(uiImage: image)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.padding()
						.shadow(radius: 5)
						.padding(.top, 20)
				} else {
					Image(systemName: "xmark.circle.fill")
						.padding(.top, 20)
				}
				
				Text("\(nowPlaying)")
					.font(.headline)
					.fontWeight(.bold)
					.foregroundColor(.white)
				
				Text("\(artist)")
					.font(.subheadline)
					.foregroundColor(.white)
				
				HStack(alignment: .center, spacing: 50) {
					Button {
						makeRequest("prev", forClient: client)
					} label: {
						Image(systemName: "backward.end.fill")
							.foregroundColor(.white)
							.font(.largeTitle)
					}
					
					Button {
						makeRequest("playpause", forClient: client)
					} label: {
						playbackStatus
							.foregroundColor(.white)
							.font(.largeTitle)
					}
					
					Button {
						makeRequest("next", forClient: client)
					} label: {
						Image(systemName: "forward.end.fill")
							.foregroundColor(.white)
							.font(.largeTitle)
					}
				}
				.padding(.top, 40)
				
				Spacer()
			}
		}
		.onReceive(timer) { _ in
			if let song = makeRequest("song", forClient: client) { //get current song
				nowPlaying = song.dropLast() + ""
				if let artist = makeRequest("artist", forClient: client) {
					self.artist = artist.dropLast() + ""
				}
			}
			
			if let status = makeRequest("playbackstatus", forClient: client) {
				if status.dropLast() == "▮▮" {
					playbackStatus = Image(systemName: "play.fill")
				} else {
					playbackStatus = Image(systemName: "pause.fill")
				}
			}
			
			if let url = makeRequest("arturl", forClient: client) {
				artURL = url.dropLast().replacingOccurrences(of: "open.spotify.com", with: "i.scdn.co")
			}
			
			guard let url = URL(string: artURL) else {
				print("Invalid URL: \(artURL)")
				return
			}
			
			self.artLoader.load(url: url)
		}
		.onReceive(artLoader.objectWillChange) { image in
			self.image = image
		}
		.onDisappear {
			self.artLoader.cancel()
		}
    }
	
	func makeRequest(_ request: String, forClient client: TCPClient) -> String? {
		var response: String? = nil
		switch client.connect(timeout: 10) {
			case .success:
				switch client.send(string: request) {
					case .success:
						guard let data = client.read(1024*10) else { return nil }
						
						if let socketResponse = String(bytes: data, encoding: .utf8) {
							response = socketResponse
						}
					case .failure(_):
						return nil
				}
			case .failure(let error):
				print("Error when connecting to socket \(error.localizedDescription)")
		}
		
		return response
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
