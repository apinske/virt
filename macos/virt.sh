#!/bin/sh

xcodebuild -project virt/virt.xcodeproj
virt/build/Release/virt $@
