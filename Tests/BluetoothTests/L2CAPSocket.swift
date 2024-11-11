//
//  L2CAPSocket.swift
//  BluetoothTests
//
//  Created by Alsey Coleman Miller on 3/30/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

#if canImport(BluetoothGATT)
import Foundation
@testable import Bluetooth
@testable import BluetoothGATT

/// Test L2CAP socket
internal final class TestL2CAPSocket: L2CAPSocket {
    
    typealias Data = Foundation.Data
        
    private enum Cache {
        
        static var pendingClients = [BluetoothAddress: [TestL2CAPSocket]]()
        
        static func queue(client socket: TestL2CAPSocket, server: BluetoothAddress) {
            pendingClients[server, default: []].append(socket)
        }
        
        static func dequeue(server: BluetoothAddress) -> TestL2CAPSocket? {
            guard let socket = pendingClients[server]?.first else {
                return nil
            }
            pendingClients[server]?.removeFirst()
            return socket
        }
    }
    
    static func lowEnergyClient(
        address: BluetoothAddress,
        destination: BluetoothAddress,
        isRandom: Bool
    ) throws(POSIXError) -> TestL2CAPSocket {
        let socket = TestL2CAPSocket(
            address: address,
            name: "Client"
        )
        Cache.queue(client: socket, server: destination)
        return socket
    }
    
    static func lowEnergyServer(
        address: BluetoothAddress,
        isRandom: Bool,
        backlog: Int
    ) throws(POSIXError) -> TestL2CAPSocket {
        return TestL2CAPSocket(
            address: address,
            name: "Server"
        )
    }
    
    // MARK: - Properties
    
    let name: String
    
    let address: BluetoothAddress
    
    var event: ((L2CAPSocketEvent<POSIXError>) -> ())?
    
    func securityLevel() throws(POSIXError) -> Bluetooth.SecurityLevel {
        _securityLevel
    }
    
    private var _securityLevel: Bluetooth.SecurityLevel = .sdp

    /// Attempts to change the socket's security level.
    func setSecurityLevel(_ securityLevel: SecurityLevel) throws(POSIXError) {
        _securityLevel = securityLevel
    }
    
    /// Target socket.
    private weak var target: TestL2CAPSocket?
    
    fileprivate(set) var receivedData = [Foundation.Data]()
    
    private(set) var cache = [Foundation.Data]()
    
    // MARK: - Initialization
    
    private init(
        address: BluetoothAddress = .zero,
        name: String
    ) {
        self.address = address
        self.name = name
    }
    
    // MARK: - Methods
    
    func close() {
        
    }
    
    func accept() throws(POSIXError) -> TestL2CAPSocket {
        // sleep until a client socket is created
        guard let client = Cache.dequeue(server: address) else {
            throw POSIXError(.EAGAIN)
        }
        let newConnection = TestL2CAPSocket(address: client.address, name: "Server connection")
        // connect sockets
        newConnection.connect(to: client)
        client.connect(to: newConnection)
        return newConnection
    }
    
    /// Write to the socket.
    func send(_ data: Data) throws(POSIXError) {
        
        print("L2CAP Socket: \(name) will send \(data.count) bytes")
        
        guard let target = self.target
            else { throw POSIXError(.ECONNRESET) }
        
        target.receive(data)
        event?(.didWrite(data.count))
    }
    
    /// Reads from the socket.
    func receive(_ bufferSize: Int) throws(POSIXError) -> Data {
        
        print("L2CAP Socket: \(name) will read \(bufferSize) bytes")
        
        while self.receivedData.isEmpty {
            guard self.target != nil
                else { throw POSIXError(.ECONNRESET) }
        }
        
        let data = self.receivedData.removeFirst()
        cache.append(data)
        event?(.didRead(data.count))
        return data
    }
    
    fileprivate func receive(_ data: Data) {
        receivedData.append(data)
        print("L2CAP Socket: \(name) received \([UInt8](data))")
        event?(.read)
    }
    
    internal func connect(to socket: TestL2CAPSocket) {
        self.target = socket
        event?(.connection)
    }
}
#endif
