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
	
    var body: some View {
		VStack {
			Spacer(minLength: 30)
			
			ZStack {
				Rectangle().fill(Color.red)
				
				HStack {
					Text("\(nowPlaying)").font(.headline)
					
					Spacer()
				}
				.padding()
			}
		}
		.onReceive(timer) { _ in
			if let song = makeRequest("song", forClient: client) {
				if let artist = makeRequest("artist", forClient: client) {
					nowPlaying = artist.dropLast() + " - " + song.dropLast()
				}
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
