//
//  main.swift
//  virt
//
//  Created by Alexander Pinske on 06.12.20.
//

import Virtualization

let verbose = CommandLine.arguments.contains("-v")

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

if (access("vdb.img", F_OK) != 0) {
    if (fclose(fopen("vdb.img", "w")) != 0) {
        perror("create vdb.img")
        exit(1)
    }
    if (truncate("vdb.img", 16 * 1024 * 1024 * 1024) != 0) {
        perror("resize vdb.img")
        exit(1)
    }
}

let config = VZVirtualMachineConfiguration()
config.cpuCount = 2
config.memorySize = 4 * 1024 * 1024 * 1024

do {
    let vda = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vda.img"), readOnly: false)
    let vdb = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vdb.img"), readOnly: false)
    config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: vda), VZVirtioBlockDeviceConfiguration(attachment: vdb)]
} catch {
    fatalError("Virtual Machine Storage Error: \(error)")
}

config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

let network = VZVirtioNetworkDeviceConfiguration()
if let macAddressString = try? String(contentsOfFile: ".virt.mac", encoding: .utf8),
   let macAddress = VZMACAddress(string: macAddressString.trimmingCharacters(in: .whitespacesAndNewlines)) {
    network.macAddress = macAddress
} else {
    let macAddressString = network.macAddress.string
    NSLog("Using new MAC Address \(macAddressString)")
    do {
        try macAddressString.write(toFile: ".virt.mac", atomically: false, encoding: .utf8)
    } catch {
        fatalError("Virtual Machine Config Error: \(error)")
    }
}
network.attachment = VZNATNetworkDeviceAttachment()
config.networkDevices = [network]

let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: "vmlinuz"))
bootloader.commandLine = "console=hvc0 root=/dev/vda" + (verbose ? "" : " quiet")
config.bootLoader = bootloader

let fs0 = VZVirtioFileSystemDeviceConfiguration(tag: "fs0")
fs0.share = VZMultipleDirectoryShare(directories: [
    "home": VZSharedDirectory(url: FileManager.default.homeDirectoryForCurrentUser, readOnly: false),
])
config.directorySharingDevices = [fs0]

if VZLinuxRosettaDirectoryShare.availability == .installed {
    let rosetta = VZVirtioFileSystemDeviceConfiguration(tag: "rosetta")
    rosetta.share = try VZLinuxRosettaDirectoryShare()
    config.directorySharingDevices += [rosetta]
}

let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
serial.attachment = VZFileHandleSerialPortAttachment(
    fileHandleForReading: FileHandle.standardInput,
    fileHandleForWriting: FileHandle.standardOutput
)
config.serialPorts = [serial]

do {
    try config.validate()
} catch {
    fatalError("Virtual Machine Config Error: \(error)")
}
let vm = VZVirtualMachine(configuration: config)
class VMDelegate : NSObject, VZVirtualMachineDelegate {
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        if verbose { NSLog("Virtual Machine Stopped") }
        exit(0)
    }

    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        fatalError("Virtual Machine Run Error: \(error)")
    }
}
let delegate = VMDelegate()
vm.delegate = delegate
vm.start { result in
    switch result {
    case .success:
        if verbose { NSLog("Virtual Machine Started") }
    case let .failure(error):
        fatalError("Virtual Machine Start Error: \(error)")
    }
}
dispatchMain()
