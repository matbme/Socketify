//
//  ContentView.swift
//  Socketify
//
//  Created by Mateus Melchiades on 26/09/20.
//

import SwiftUI
import SwiftSocket

struct ContentView: View {
	let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
	
	@State private var client = TCPClient(address: "192.168.0.15", port: 8888)
	@State private var nowPlaying: String = ""
	@State private var playbackStatus: Image = Image(systemName: "icloud.slash")
	@State private var artURL: String = ""
	
    var body: some View {
		VStack {
			getImageFromURL(forURL: artURL)
			
			ZStack {
				Rectangle()
					.fill(Color.red)
					.frame(height: 50)
				
				HStack {
					Text("\(nowPlaying)")
						.font(.callout)
						.foregroundColor(.white)
						.lineLimit(2)
					
					Spacer()
					
					HStack(alignment: .center, spacing: 20) {
						Button {
							makeRequest("prev", forClient: client)
						} label: {
							Image(systemName: "backward.end.fill")
								.foregroundColor(.white)
						}
						
						Button {
							makeRequest("playpause", forClient: client)
						} label: {
							playbackStatus
								.foregroundColor(.white)
						}
						
						Button {
							makeRequest("next", forClient: client)
						} label: {
							Image(systemName: "forward.end.fill")
								.foregroundColor(.white)
						}
					}
				}
				.padding()
			}
		}
		.onReceive(timer) { _ in
			if let song = makeRequest("song", forClient: client) { //get current song
				if let artist = makeRequest("artist", forClient: client) {
					nowPlaying = artist.dropLast() + "\n" + song.dropLast()
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
				artURL = url.dropLast() + ""
			}
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
	
	func getImageFromURL(forURL: String) -> Image {
		let replacedURL = forURL.dropLast().replacingOccurrences(of: "open.spotify.com", with: "i.scdn.co")
		
		guard let url = URL(string: replacedURL) else {
			print("Invalid URL: \(replacedURL)")
			return Image(systemName: "xmark.circle.fill")
		}
		
		let request = URLRequest(url: url)
		
		URLSession.shared.dataTask(with: request) { data, response, error in
			if let data = data {
				print("data: ")
				print(String(data: data, encoding: .utf8))
				if let decodedResponse = try? JSONDecoder().decode(String.self, from: data) {
					DispatchQueue.main.async {
						print(decodedResponse)
					}
					return
				}
			} else {
				print("No data")
			}
			print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
		}.resume()
		
		return Image(systemName: "xmark.circle.fill")
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
