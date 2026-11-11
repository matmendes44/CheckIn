//
//  CheckInApp.swift
//  CheckIn
//
//  Created by Matheus Mendes on 10/23/26.
//

import SwiftUI
import FirebaseCore

@main
struct CheckInApp: App {
    
    init() {
        //Reads GoogleServices-info and must run before any firebase call
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {await AppServices.shared.restoreSession() }
        }
    }
}
