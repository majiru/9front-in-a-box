## 9front-in-a-box

This repo provides a nix flake for automating the setup
and running of 9front virtual machines. Virtual machines
are run using qemu and connecting to them is done with
drawterm.

These are made as a sort of demo, to reduce the friction
for trying out the system without needing to futz with
qemu and configuration. They are not (really) intended
to be used generally for running 9front servers, but
may serve as a good starting point for those interested
in doing so.

## Setup

The vms are configured in a way where a read only "parent"
qcow2 is kept in the nix store and used as the backing file
for the writable COW image. As such a first time setup needs
to be run to create this new writable qcow2 image first.

```
nix run github:majiru/9front-in-a-box#setup-vm
```

Will download the source qcow2, configure it and place a
`9front.amd64.qcow2` in to the current directory. Because
the parent is read only and kept around, if for some reason
you have imploded your disk you may rerun the setup without
needing to redownload and configure the parent qcow2.

## Running

```
nix run github:majiru/9front-in-a-box#run-vm
```

Will then start the new virtual machine and run drawterm
to connect to it. The password for glenda is 'password'.

Instructions for using rio for first timers may be found in the
[9front FQA](http://fqa.9front.org/fqa8.html). 

## Tunables

This flake also provides scripts for using cwfs instead of hjfs and
also is capable of running the arm64 virtual machines of 9front as well.

These different configurations are exposed via different packages, the convention
is `setup-vm-$FS-$ARCH`  and `run-vm-$FS-$ARCH`. So to run a cwfs arm64 install you
may use `run-vm-cwfs-arm64`.


### Drawterm

Drawterm is the graphical program used to connect to the virtual machine.
This flake will use a copy of drawterm from nixpkgs that is built for
X11 and pulseaudio. Nixpkgs also contains a drawterm build (`drawterm-wayland`) for wayland
and pipewire. The drawterm binary used by `run-vm` may be changed by passing a `-dt` flag.

```
 # Use the wayland drawterm
 nix-shell -p drawterm-wayland
 # or with nix shell
 nix shell 'nixpkgs#drawterm-wayland'

 nix run 'github:majiru/9front-in-a-box#run-vm' -- -dt drawterm
```
