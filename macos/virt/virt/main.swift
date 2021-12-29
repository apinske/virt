//
//  main.swift
//  virt
//
//  Created by Alexander Pinske on 06.12.20.
//

import SwiftUI
import Virtualization

@main
struct virt: App {
    var vm = VM()
    var body: some Scene {
        WindowGroup {
        }
    }
}

class VM : NSObject, VZVirtualMachineDelegate {
    let verbose = CommandLine.arguments.contains("-v")
    var vm: VZVirtualMachine

    override init() {
        let tcattr = UnsafeMutablePointer<termios>.allocate(capacity: 1)
        tcgetattr(FileHandle.standardInput.fileDescriptor, tcattr)
        let oldValue = tcattr.pointee.c_lflag
        atexit_b {
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
            if (truncate("vdb.img", 10 * 1024 * 1024 * 1024) != 0) {
                perror("resize vdb.img")
                exit(1)
            }
        }

        let config = VZVirtualMachineConfiguration()
        config.cpuCount = 2
        config.memorySize = 2 * 1024 * 1024 * 1024

        do {
            let vda = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vda.img"), readOnly: false)
            config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: vda)]
        } catch {
            fatalError("Virtual Machine Primary Storage Error: \(error)")
        }

        do {
            let vdb = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vdb.img"), readOnly: false)
            config.storageDevices += [VZVirtioBlockDeviceConfiguration(attachment: vdb)]
        } catch {
            fatalError("Virtual Machine Secondary Storage Error: \(error)")
        }

        let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: "vmlinuz"))
        bootloader.commandLine = "console=hvc0 root=/dev/vda" + (verbose ? "" : " quiet")
        config.bootLoader = bootloader

        let fs0 = VZVirtioFileSystemDeviceConfiguration(tag: "fs0")
        fs0.share = VZMultipleDirectoryShare(directories: [
            "home": VZSharedDirectory(url: FileManager.default.homeDirectoryForCurrentUser, readOnly: false),
        ])
        config.directorySharingDevices = [fs0]

        let serial = VZVirtioConsoleDeviceSerialPortConfiguration()
        serial.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: FileHandle.standardOutput
        )
        config.serialPorts = [serial]

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

        do {
            try config.validate()
        } catch {
            NSLog("Virtual Machine Config Error: \(error)")
            exit(2)
        }

        vm = VZVirtualMachine(configuration: config)
        super.init()
        vm.delegate = self

        vm.start { result in
            switch result {
            case .success:
                if self.verbose { NSLog("Virtual Machine Started") }
            case let .failure(error):
                fatalError("Virtual Machine Start Error: \(error)")
            }
        }
    }

    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        if verbose { NSLog("Virtual Machine Stopped") }
        exit(0)
    }

    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        fatalError("Virtual Machine Run Error: \(error)")
    }
}
