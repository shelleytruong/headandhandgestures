import Foundation
import UIKit
import CoreMotion
import os

class ViewController: UIViewController, CMHeadphoneMotionManagerDelegate, StreamDelegate {
    
    let motionManager = CMMotionManager()
    let headphoneMotionManager = CMHeadphoneMotionManager()
    
    let host = "192.168.0.37" // Replace with Mac's IP address
    let port = 242// Replace with a port number of your choice
    let bufferSize = 1024

    
    var outputStream: OutputStream!
    var inputStream: InputStream!
     
    

     
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connect()
        startMotion()
    }
    
    func startMotion() {
    
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/ddHH:mm:ss.SSS"

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 25.0 // Set the update interval to 25 Hz
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { (data, error) in
                guard let deviceMotion = data else {
                    print("Failed to get device motion data: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                let currentTimeString = dateFormatter.string(from: Date())

                
                self.send(data:"iPhone,\(currentTimeString),\(deviceMotion.userAcceleration.x),\(deviceMotion.userAcceleration.y),\(deviceMotion.userAcceleration.z),\(deviceMotion.rotationRate.x),\(deviceMotion.rotationRate.y),\(deviceMotion.rotationRate.z),\(deviceMotion.magneticField.field.x),\(deviceMotion.magneticField.field.y),\(deviceMotion.magneticField.field.z)".data(using: .utf8)!)
            }
        } else {
            print("Device motion is not available.")
        }

        
        if headphoneMotionManager.isDeviceMotionAvailable{
            self.headphoneMotionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                guard let motion = motion, error == nil else { return }
                let currentTimeString = dateFormatter.string(from: Date())
                self.send( data:"AirPods,\(currentTimeString),\(motion.userAcceleration.x),\(motion.userAcceleration.y),\(motion.userAcceleration.z),\(motion.rotationRate.x),\(motion.rotationRate.y),\(motion.rotationRate.z)".data(using: .utf8)!)
                
            }
        }
          
    }
  
    func connect() {
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, host as CFString, UInt32(port), &readStream, &writeStream)
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        inputStream?.delegate = self

        outputStream.schedule(in: .main, forMode: .common)
        inputStream?.schedule(in: .main, forMode: .common)
        outputStream.open()
        inputStream.open()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            switch eventCode {
            case .hasBytesAvailable:
                readAvailableBytes(stream: aStream as! InputStream)
            case .endEncountered:
                print("End Encountered")
            case .errorOccurred:
                print("Error Occurred")
            case .hasSpaceAvailable:
                print("Has Space Available")
            default:
                print("Unknown event")
            }
        }
    func readAvailableBytes(stream: InputStream) {
          let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
          while stream.hasBytesAvailable {
              let numberOfBytesRead = inputStream?.read(buffer, maxLength: 1024)
              if numberOfBytesRead! < 0 {
                  if let _ = stream.streamError {
                      break
                  }
              }
              let data = Data(bytes: buffer, count: numberOfBytesRead!)
             // print(data)
          }
          buffer.deallocate()
      }
    
    func send(data: Data) {
        let bytesWritten = data.withUnsafeBytes {
            outputStream.write($0, maxLength: data.count)
        }
    }
}
   
