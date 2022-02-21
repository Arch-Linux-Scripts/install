# arch-install

## Requirements
```
x86_64 system
EFI compatile
Internet connection
```

## Usage
Follow the installation instructions from https://wiki.archlinux.org/title/Installation_guide and create a bootable usb drive. Disable secure boot and boot the drive.
From this state you can continue by cloning this repo and running the script, though it is recomended to complete the installation using ssh.
```
pacman -Sy && pacman -S git
git clone https://gitlab.com/zqu1cks/arch-install.git
./arch-install/c-install.sh
```
###Using ssh:
Start the ssh server on the installation
```
passwd # Choose a password
systemctl start sshd # Start ssh server
ip a # To show the ip
```
SSH into the installation and start the installer
```
pacman -Sy && pacman -S git
git clone https://gitlab.com/zqu1cks/arch-install.git
./arch-install/c-install.sh
```

## General info:

### bare.sh dir
This directory includes the clean .sh installation files without modifications. These are the ones that should be modified.

### c-install.sh
This file is a combination of all .sh files in bare.sh

This file is created by replacing every "$" with rm-ts except for the variables (passed from the initial script) at the top of chroot-install.sh.
Every " in the file is also replaced with \" so that it can be stored in the c-install.sh (c stands for complete) as a single variable.
