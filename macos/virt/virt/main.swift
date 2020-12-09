//
//  main.swift
//  virt
//
//  Created by Alexander Pinske on 06.12.20.
//

import Foundation
import Virtualization

print(VZVirtualMachineConfiguration.minimumAllowedCPUCount)
print(VZVirtualMachineConfiguration.maximumAllowedCPUCount)
print(VZVirtualMachineConfiguration.minimumAllowedMemorySize)
print(VZVirtualMachineConfiguration.maximumAllowedMemorySize)

let c = VZVirtualMachineConfiguration()
let z = URL(fileURLWithPath: "vmlinuz").absoluteURL
print(z)
let b = VZLinuxBootLoader(kernelURL: z)
b.commandLine = "console=ttyS0"
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
    }
    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        print(error)
        exit(1)
    }
}

//let att = try? VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "disk").absoluteURL, readOnly: false)
//let disk = VZVirtioBlockDeviceConfiguration(attachment: att!)
//c.storageDevices = [disk]

let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
serial.attachment = VZFileHandleSerialPortAttachment(
    fileHandleForReading: FileHandle.standardInput,
    fileHandleForWriting: FileHandle.standardOutput
)
c.serialPorts = [serial]

print(VZVirtualMachine.isSupported)

let vm = VZVirtualMachine(configuration: c)
let d = D()
vm.delegate = d
print(vm.canStart)
print(vm.state.rawValue)
vm.start { r in
    print(vm.state.rawValue)
    switch r {
    case .success:
        NSLog("Virtual Machine Started")
    case let .failure(error):
        print(error)
        NSLog("Virtual Machine Failure: \(error)")
        exit(1)
    }}

dispatchMain()
