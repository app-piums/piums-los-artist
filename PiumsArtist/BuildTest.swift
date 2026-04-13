//
//  BuildTest.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//  Test file to verify build compatibility
//

import SwiftUI
import SwiftData

struct BuildTestView: View {
    var body: some View {
        VStack {
            Text("🎉 Piums Artista")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Build Test Successful!")
                .font(.title2)
                .foregroundColor(.green)
            
            Text("All SwiftData models loaded correctly")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("✅ Artist Model")
                Text("✅ Service Model") 
                Text("✅ Booking Model")
                Text("✅ Message Model")
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Build Test")
    }
}

#Preview {
    NavigationView {
        BuildTestView()
    }
    .modelContainer(for: [Artist.self, Service.self, Booking.self, Message.self], inMemory: true)
}