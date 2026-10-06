//
//  NetworkManager.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 11/08/26.
//

import Foundation
import Network
import Combine

final class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected: Bool = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
