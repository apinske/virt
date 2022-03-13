# virt
small Linux VM, ready to run containers, for macOS (x86 and arm)

## Usage
* on macOS
  * get VM: `curl -Lo- https://github.com/apinske/virt/releases/download/v0.5/virt_$(uname -m).tar.gz | tar xzf -`
  * run VM: `./virt`
* in VM
  * `apk upgrade`
  * `./setup-vdb.sh`
  * `./setup-podman.sh`
  * to test: `podman run --rm -it alpine`
  * $HOME is mounted at /mnt/virt/home

## Components
### Kernel
* based on 5.15 longterm
* small set of features
* only virtio drivers

### Userland
* based on Alpine 3.15
* stripped down

### Hypervisor
* based on Apple Virtualization.framework

## macOS VM (arm only)
* `curl -Lo virt https://github.com/apinske/virt/releases/download/v0.5/virt`
* `chmod +x ./virt`
* `./virt -m`
