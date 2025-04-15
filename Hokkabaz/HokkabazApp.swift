//
//  HokkabazApp.swift
//  Hokkabaz
//
//  Created by Can Dindar on 28/02/25.
//

import SwiftUI

//@main
//struct HokkabazApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
@main
struct HokkabazApp: App {
    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad {
                ContentView() // iPad
            } else {
                Phone2() // iPhone
            }
        }
    }
}
