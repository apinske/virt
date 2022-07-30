#!/bin/sh
xcodebuild -project virt/virt.xcodeproj -arch arm64
virt/build/Release/virt $@
