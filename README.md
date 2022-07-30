# virt
small Linux VM, ready to run containers, for macOS on ARM

## Usage
* on macOS
  * get VM: `curl -Lo- https://github.com/apinske/virt/releases/download/v0.6/virt.tar.gz | tar xzf -`
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
