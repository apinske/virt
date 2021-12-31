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
            if !vm.linux {
                VMScreen(vm: vm.vm)
            }
        }
    }
}

struct VMScreen: NSViewRepresentable {
    var vm: VZVirtualMachine?

    func makeNSView(context: Context) -> VZVirtualMachineView {
        let view = VZVirtualMachineView()
        view.capturesSystemKeys = true
        return view
    }

    func updateNSView(_ view: VZVirtualMachineView, context: Context) {
        view.virtualMachine = vm
        view.window?.makeFirstResponder(view)
    }
}

class VM : NSObject, VZVirtualMachineDelegate {
    let verbose = CommandLine.arguments.contains("-v")
    let linux = !CommandLine.arguments.contains("-m")
    var vm: VZVirtualMachine!
    private let config = VZVirtualMachineConfiguration()
    private var needsInstall = false

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
            if (truncate("vdb.img", 64 * 1024 * 1024 * 1024) != 0) {
                perror("resize vdb.img")
                exit(1)
            }
        }

        config.cpuCount = 2
        config.memorySize = 4 * 1024 * 1024 * 1024

        if linux {
            do {
                let vda = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vda.img"), readOnly: false)
                config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: vda)]
            } catch {
                fatalError("Virtual Machine Primary Storage Error: \(error)")
            }
        }

        do {
            let vdb = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: "vdb.img"), readOnly: false)
            config.storageDevices += [VZVirtioBlockDeviceConfiguration(attachment: vdb)]
        } catch {
            fatalError("Virtual Machine Secondary Storage Error: \(error)")
        }

        if linux {
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
        } else {
#if arch(arm64)
            let video = VZMacGraphicsDeviceConfiguration()
            video.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1024, heightInPixels: 768, pixelsPerInch: 80)]
            config.graphicsDevices = [video]
            config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
            config.keyboards = [VZUSBKeyboardConfiguration()]

            config.bootLoader = VZMacOSBootLoader()
            if (access(".virt.aux", F_OK) != 0) {
                needsInstall = true
            } else {
                let mac = VZMacPlatformConfiguration()
                mac.auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: URL(fileURLWithPath: ".virt.aux"))
                mac.hardwareModel = VZMacHardwareModel(dataRepresentation: try! Data(contentsOf: URL(fileURLWithPath: ".virt.model")))!
                mac.machineIdentifier = VZMacMachineIdentifier(dataRepresentation: try! Data(contentsOf: URL(fileURLWithPath: ".virt.id")))!
                config.platform = mac
            }
#else
            fatalError("not supported")
#endif
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

        super.init()
        if needsInstall {
            Task {
                await self.install()
            }
        } else {
            self.create()
            self.start()
        }
    }

    func create() {
        do {
            try config.validate()
        } catch {
            fatalError("Virtual Machine Config Error: \(error)")
        }

        vm = VZVirtualMachine(configuration: config)
        vm.delegate = self
    }

    func start() {
        vm.start { result in
            switch result {
            case .success:
                if self.verbose { NSLog("Virtual Machine Started") }
            case let .failure(error):
                fatalError("Virtual Machine Start Error: \(error)")
            }
        }
    }

    @MainActor
    func install() async {
#if arch(arm64)
        let restoreImageURL = URL(fileURLWithPath: "restore.ipsw")
        if !FileManager.default.fileExists(atPath: restoreImageURL.path) {
            NSLog("Downloading...")
            let image = try! await VZMacOSRestoreImage.latestSupported
            let (url, _) = try! await URLSession.shared.download(from: image.url)
            try! FileManager.default.moveItem(at: url, to: restoreImageURL)
        }
        let image = try! await VZMacOSRestoreImage.image(from: restoreImageURL)
        let mac = VZMacPlatformConfiguration()
        mac.hardwareModel = image.mostFeaturefulSupportedConfiguration!.hardwareModel
        try! mac.hardwareModel.dataRepresentation.write(to: URL(fileURLWithPath: ".virt.model"))
        mac.auxiliaryStorage = try! VZMacAuxiliaryStorage(creatingStorageAt: URL(fileURLWithPath: ".virt.aux"), hardwareModel: mac.hardwareModel, options: [])
        mac.machineIdentifier = VZMacMachineIdentifier()
        try! mac.machineIdentifier.dataRepresentation.write(to: URL(fileURLWithPath: ".virt.id"))
        config.platform = mac
        self.create()
        NSLog("Installing...")
        try! await VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: restoreImageURL).install()
        NSLog("Stopping...")
        try! await vm.stop()
        exit(0)
#endif
    }

    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        if verbose { NSLog("Virtual Machine Stopped") }
        exit(0)
    }

    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        fatalError("Virtual Machine Run Error: \(error)")
    }
}
