//
//  main.swift
//  location-tether-server
//
//  Created by Michael Rooplall on 6/12/24.
//

import Foundation
import FlyingFox

print("Hello, World!")

func checkForLibimobiledevice() -> Bool {
    return true
}

struct Coordinates {
    var latitude : Double = 0.0
    var longitude : Double = 0.0
    var heading : Double = 0.0
}

func setLocation(deviceUUID : String, location : Coordinates ) {
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/idevicelocation")
    task.arguments = ["-u", deviceUUID, "\(location.latitude)", "\(location.longitude)"]
    
    do {
        try task.run()
        task.waitUntilExit()
        print("Location set on device \(deviceUUID) to: Latitude: \(location.latitude), Longitude: \(location.longitude)")
    } catch {
        print("Error setting location: \(error)")
    }
    
}

func clearSpoofedLocation(deviceUUID : String) {
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/idevicelocation")
    task.arguments = ["-u", deviceUUID, "-c"]
    
    do {
        try task.run()
        task.waitUntilExit()
        print("Location spoofing reverted on device \(deviceUUID).")
    } catch {
        print("Error reverting location spoofing: \(error)")
    }
    
}

// Function to list connected iOS devices
func listConnectedDevices() {
    let pipe = Pipe()
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/local/bin/idevice_id")
    task.arguments = ["-l"]
    task.standardOutput = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            if output.isEmpty {
                print("No iOS devices connected.")
            } else {
                let devices = output.components(separatedBy: "\n")
                print("Connected iOS devices:")
                for device in devices {
                    print(device)
                }
            }
        }
    } catch {
        print("Error listing devices: \(error)")
    }
}

func makeServer(from args: [String] = Swift.CommandLine.arguments) -> HTTPServer {
    guard let path = parsePath(from: args) else {
        return HTTPServer(port: parsePort(from: args) ?? 8080, logger: .print())
    }
    var addr = sockaddr_un.unix(path: path)
    unlink(&addr.sun_path.0)
    return HTTPServer(address: addr, logger: .print())
}

func parsePath(from args: [String]) -> String? {
    var last: String?
    for arg in args {
        if last == "--path" {
            return arg
        }
        last = arg
    }
    return nil
}

func parsePort(from args: [String]) -> UInt16? {
    var last: String?
    for arg in args {
        if last == "--port" {
            return UInt16(arg)
        }
        last = arg
    }
    return nil
}

let server = makeServer()

await server.appendRoute("/hello") { _ in
    HTTPResponse(statusCode: .ok,
         headers: [.contentType: "text/plain; charset=UTF-8"],
         body: "Hello World! 🦊".data(using: .utf8)!)
}

try await server.start()
