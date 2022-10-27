# virt
small Linux VM, ready to run containers, for macOS on ARM

## Usage
* on macOS
  * `curl -Lo- https://github.com/apinske/virt/releases/download/v0.8/virt.tar.gz | tar xzf -`
  * `./virt`
* in VM
  * `apk upgrade`
  * `./setup-vdb.sh`
  * `./setup-podman.sh`
    * to test: `podman run --rm -it alpine`
  * `./setup-rosetta.sh`
    * to test: `podman run --rm -it --arch amd64 alpine`
  * `./setup-k3d.sh`
    * to test: `kubectl create deployment nginx --image nginx`
  * $HOME is mounted at /mnt/virt/home
* ssh
  * `apk add dropbear && reboot`
  * `ssh root@$(ndp -an | grep $(cat .virt.mac) | awk '{print $1}')`

## Components
### Kernel
* based on 5.15 longterm
* small set of features
* only virtio drivers

### Userland
* based on Alpine 3.16
* stripped down

### Hypervisor
* based on Apple Virtualization.framework
