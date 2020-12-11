//
//  main.swift
//  virt
//
//  Created by Alexander Pinske on 06.12.20.
//

import Foundation
import Virtualization

func enableRawMode(fileHandle: FileHandle) {
    let pointer = UnsafeMutablePointer<termios>.allocate(capacity: 1)
    tcgetattr(fileHandle.fileDescriptor, pointer)
    pointer.pointee.c_lflag &= ~UInt(ECHO | ICANON)
    tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, pointer)
}

let c = VZVirtualMachineConfiguration()
let z = URL(fileURLWithPath: "vmlinuz").absoluteURL
let b = VZLinuxBootLoader(kernelURL: z)
b.commandLine = "console=hvc0 root=/dev/vda rw"
c.bootLoader = b
c.cpuCount = 1
c.memorySize = 512 * 1024 * 1024
do {
    try c.validate()
} catch {
    print("error")
    exit(1)
}

class D : NSObject, VZVirtualMachineDelegate {
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        print("stop")
        exit(0)
    }
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        print(error)
        exit(1)
    }
}

let att = try? VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vda.img").absoluteURL, readOnly: false)
let disk = VZVirtioBlockDeviceConfiguration(attachment: att!)
c.storageDevices = [disk]

enableRawMode(fileHandle: FileHandle.standardInput)
let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
serial.attachment = VZFileHandleSerialPortAttachment(
    fileHandleForReading: FileHandle.standardInput,
    fileHandleForWriting: FileHandle.standardOutput
)
c.serialPorts = [serial]

//let entropy = VZVirtioEntropyDeviceConfiguration()
//c.entropyDevices = [entropy]
//let memoryBalloon = VZVirtioTraditionalMemoryBalloonDeviceConfiguration()
//c.memoryBalloonDevices = [memoryBalloon]

let networkDevice = VZVirtioNetworkDeviceConfiguration()
networkDevice.macAddress = VZMACAddress(string: "0A:00:00:00:00:03")!
networkDevice.attachment = VZNATNetworkDeviceAttachment()
c.networkDevices = [networkDevice]

let vm = VZVirtualMachine(configuration: c)
let d = D()
vm.delegate = d
vm.start { r in
    switch r {
    case .success:
        NSLog("Virtual Machine Started")
    case let .failure(error):
        print(error)
        NSLog("Virtual Machine Failure: \(error)")
        exit(1)
    }
}

dispatchMain()
