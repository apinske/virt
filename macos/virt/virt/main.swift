//
//  main.swift
//  virt
//
//  Created by Alexander Pinske on 06.12.20.
//

import Foundation
import Virtualization

let tcattr = UnsafeMutablePointer<termios>.allocate(capacity: 1)
tcgetattr(FileHandle.standardInput.fileDescriptor, tcattr)
let oldValue = tcattr.pointee.c_lflag
atexit {
    tcattr.pointee.c_lflag = oldValue
    tcsetattr(FileHandle.standardInput.fileDescriptor, TCSAFLUSH, tcattr)
    tcattr.deallocate()
}
tcattr.pointee.c_lflag &= ~UInt(ECHO | ICANON | ISIG)
tcsetattr(FileHandle.standardInput.fileDescriptor, TCSAFLUSH, tcattr)

let config = VZVirtualMachineConfiguration()
config.cpuCount = 2
config.memorySize = 2 * 1024 * 1024 * 1024

let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: "vmlinuz"))
bootloader.commandLine = "console=hvc0 root=/dev/vda"
config.bootLoader = bootloader

do {
    let vda = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vda.img"), readOnly: false)
    config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: vda)]
} catch {
    NSLog("Virtual Machine Storage Error: \(error)")
    exit(1)
}

// TODO secondary writable storage

let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
serial.attachment = VZFileHandleSerialPortAttachment(
    fileHandleForReading: FileHandle.standardInput,
    fileHandleForWriting: FileHandle.standardOutput
)
config.serialPorts = [serial]

config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

let network = VZVirtioNetworkDeviceConfiguration()
network.macAddress = VZMACAddress(string: "0A:00:00:00:00:03")!
network.attachment = VZNATNetworkDeviceAttachment()
config.networkDevices = [network]

do {
    try config.validate()
} catch {
    NSLog("Virtual Machine Config Error: \(error)")
    exit(2)
}

class Delegate : NSObject, VZVirtualMachineDelegate {
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        NSLog("Virtual Machine Stopped")
        exit(0)
    }
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        NSLog("Virtual Machine Run Error: \(error)")
        exit(4)
    }
}
let delegate = Delegate()

let vm = VZVirtualMachine(configuration: config)
vm.delegate = delegate

vm.start { result in
    switch result {
    case .success:
        NSLog("Virtual Machine Started")
    case let .failure(error):
        NSLog("Virtual Machine Start Error: \(error)")
        exit(3)
    }
}

dispatchMain()
