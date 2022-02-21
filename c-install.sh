#!/bin/sh
# Minimal Arch Linux installation script for later use with software like Ansible
# Installation steps from https://wiki.archlinux.org/title/Installation_guide
# Make sure you have completed these installation steps beforehand:
# Acquire an installation image
# Verify signature
# Prepare an installation medium
# Boot the live environment

### Pre-installation ###
# ARCH
if [ `uname -m` != "x86_64" ]
then
	echo "You are not installing on x86_64 hardware!"
	exit 1
fi

# Verify the boot mode #
ls /sys/firmware/efi/efivars || { echo "You are not installing on EFI compatible hardware!" ; exit 1; }

# Connect to the internet #
nc -z 1.1.1.1 53
net="$?"
if [ "$net" != "0" ]
then
	echo "You don't have a working internet connection!"
	exit 1
fi

# Set the console keyboard layout #
console_keymap() {
	echo "Choose your console keymap, answer without .map.gz"
	echo "Available keymaps can be listed with the following command:"
	echo "ls /usr/share/kbd/keymaps/**/*.map.gz"
	read console_keymap
	loadkeys $console_keymap
}

# Update the system clock #
sync_clock() {
	timedatectl set-ntp true
}

# Partition the disks & Format the partitions & Mount the file systems #
# Without_encryption
no_crypt_partitioning() {
	echo ""
	echo "= = ="
	lsblk
	echo "= = ="
	echo ""
	echo "Please select which storage medium you want to install Arch Linux on, Example: sda"
	read storage
	echo "= = ="
	echo "Arch Linux can be installed in multiple ways, for example, without a separate /home"
	echo "and swap partition. Or with one/both. This installation script does not support"
	echo "installing Arch Linux with a separeate /home partition, becaus you'll have to first"
	echo "create an user account and use the same password for mounting the /home partition."
	echo "= = ="
	echo "If you want to have a separate /home partition you'll have to configure it manually"
	echo "using examples from: https://wiki.archlinux.org/title/Dm-crypt/Mounting_at_login"
	echo "= = ="
	echo "Is this the correct storage medium?"
	echo "/dev/$storage"
	read -p "(y/n): " storage_check
	if [ "$storage_check" == "y" ] || [ "$storage_check" == "Y" ]
	then
		echo "Do you want to have a separate swap partition?"
		read -p "(y/n): " swap_check
		if [ "$swap_check" == "y" ] || [ "$swap_check" == "Y" ]
		then
			echo ""
			echo "= = ="
			echo "After the next choise, fdisk will be opened."
			echo "= = ="
			echo "Please create one EFI, SWAP and ROOT partition."
			echo "Ready?"
			read -p "(y/n): " create_partitions_check
			if [ "$create_partitions_check" == "y" ] || [ "$create_partitions_check" == "Y" ]
			then
				fdisk /dev/$storage
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Now select your partitions, Example if you created an EFI partition on /dev/sda1 type: 1"
				echo "Where is your EFI partition located?"
				read efi
				echo "Where is your SWAP partition located?"
				read swap
				echo "Where is your ROOT partition located?"
				read root
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Is this correct?"
				echo "EFI = /dev/$storage$efi"
				echo "SWAP = /dev/$storage$swap"
				echo "ROOT = /dev/$storage$root"
				read -p "(y/n): " partitions_check
				if [ "$partitions_check" == "y" ] || [ "$partitions_check" == "Y" ]
				then
					mkfs.fat -F 32 /dev/$storage$efi
					mkswap /dev/$storage$swap
					swapon /dev/$storage$swap
					mkfs.$fs /dev/$storage$root
					mount /dev/$storage$root /mnt
					mkdir -p /mnt/boot
					mount /dev/$storage$efi /mnt/boot
				else
					exit 1
				fi
			else
				exit 1
			fi
		else
			echo ""
			echo "= = ="
			echo "After the next choise, fdisk will be opened."
			echo "= = ="
			echo "Please create one EFI and ROOT partition."
			echo "Ready?"
			read -p "(y/n): " create_partitions_check
			if [ "$create_partitions_check" == "y" ] || [ "$create_partitions_check" == "Y" ]
			then
				fdisk /dev/$storage
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Now select your partitions, Example if you created an EFI partition on /dev/sda1 type: 1"
				echo "Where is your EFI partition located?"
				read efi
				echo "Where is your ROOT partition located?"
				read root
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Is this correct?"
				echo "EFI = /dev/$storage$efi"
				echo "ROOT = /dev/$storage$root"
				read -p "(y/n): " partitions_check
				if [ "$partitions_check" == "y" ] || [ "$partitions_check" == "Y" ]
				then
					mkfs.fat -F 32 /dev/$storage$efi
					mkfs.$fs /dev/$storage$root
					mount /dev/$storage$root /mnt
					mkdir -p /mnt/boot
					mount /dev/$storage$efi /mnt/boot
				else
					exit 1
				fi
			else
				exit 1
			fi
		fi
	else
		exit 1
	fi
}
# With encryption
crypt_partitioning() {
	echo ""
	echo "= = ="
	lsblk
	echo "= = ="
	echo ""
	echo "Please select which storage medium you want to install Arch Linux on, Example: sda"
	read storage
	echo "= = ="
	echo "Arch Linux can be installed in multiple ways, for example, without a separate /home"
	echo "and swap partition. Or with one/both. This installation script does not support"
	echo "installing Arch Linux with a separeate /home partition, becaus you'll have to first"
	echo "create an user account and use the same password for mounting the /home partition."
	echo "= = ="
	echo "If you want to have a separate /home partition you'll have to configure it manually"
	echo "using examples from: https://wiki.archlinux.org/title/Dm-crypt/Mounting_at_login"
	echo "= = ="
	echo "Is this the correct storage medium?"
	echo "/dev/$storage"
	read -p "(y/n): " storage_check
	if [ "$storage_check" == "y" ] || [ "$storage_check" == "Y" ]
	then
		echo "Do you want to have a separate swap partition?"
		read -p "(y/n): " swap_check
		if [ "$swap_check" == "y" ] || [ "$swap_check" == "Y" ]
		then
			echo ""
			echo "= = ="
			echo "After the next choise, fdisk will be opened."
			echo "= = ="
			echo "Please create one EFI, SWAP and ROOT partition."
			echo "Ready?"
			read -p "(y/n): " create_partitions_check
			if [ "$create_partitions_check" == "y" ] || [ "$create_partitions_check" == "Y" ]
			then
				fdisk /dev/$storage
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Now select your partitions, Example if you created an EFI partition on /dev/sda1 type: 1"
				echo "Where is your EFI partition located?"
				read efi
				echo "Where is your SWAP partition located?"
				read swap
				echo "Where is your ROOT partition located?"
				read root
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Is this correct?"
				echo "EFI = /dev/$storage$efi"
				echo "SWAP = /dev/$storage$swap"
				echo "ROOT = /dev/$storage$root"
				read -p "(y/n): " partitions_check
				if [ "$partitions_check" == "y" ] || [ "$partitions_check" == "Y" ]
				then
					mkfs.fat -F 32 /dev/$storage$efi
					mkswap /dev/$storage$swap
					swapon /dev/$storage$swap	
					cryptsetup --type luks2 --cipher aes-xts-plain64 --hash sha512 --key-size 512 -y -v luksFormat /dev/$storage$root
					crypt_open="crypt-root"
					cryptsetup --allow-discards --persistent open /dev/$storage$root $crypt_open
					root_crypt="mapper/$crypt_open"
					mkfs.$fs /dev/$root_crypt
					mount /dev/$root_crypt /mnt
					mkdir -p /mnt/boot
					mount /dev/$storage$efi /mnt/boot
				else
					exit 1
				fi
			else
				exit 1
			fi
		else
			echo ""
			echo "= = ="
			echo "After the next choise, fdisk will be opened."
			echo "= = ="
			echo "Please create one EFI and ROOT partition."
			echo "Ready?"
			read -p "(y/n): " create_partitions_check
			if [ "$create_partitions_check" == "y" ] || [ "$create_partitions_check" == "Y" ]
			then
				fdisk /dev/$storage
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Now select your partitions, Example if you created an EFI partition on /dev/sda1 type: 1"
				echo "Where is your EFI partition located?"
				read efi
				echo "Where is your ROOT partition located?"
				read root
				echo ""
				echo "= = ="
				lsblk
				echo "= = ="
				echo ""
				echo "Is this correct?"
				echo "EFI = /dev/$storage$efi"
				echo "ROOT = /dev/$storage$root"
				read -p "(y/n): " partitions_check
				if [ "$partitions_check" == "y" ] || [ "$partitions_check" == "Y" ]
				then
					mkfs.fat -F 32 /dev/$storage$efi
					cryptsetup --type luks2 --cipher aes-xts-plain64 --hash sha512 --key-size 512 -y -v luksFormat /dev/$storage$root
					crypt_open="crypt-root"
					cryptsetup --allow-discards --persistent open /dev/$storage$root $crypt_open
					root_crypt="mapper/$crypt_open"
					mkfs.$fs /dev/$root_crypt
					mount /dev/$root_crypt /mnt
					mkdir -p /mnt/boot
					mount /dev/$storage$efi /mnt/boot

				else
					exit 1
				fi
			else
				exit 1
			fi
		fi
	else
		exit 1
	fi
}
# Partitioning configuration
partitioning_configuration() {
	echo ""
	echo "What filesystem would you like to have on your ROOT partition?"
	echo "1. ext4"
	echo "2. f2fs"
	echo "3. btrfs"
	read fs_check
	if [ "$fs_check" == "1" ]
	then
		fs="ext4"
		fs_pkg=""
	elif [ "$fs_check" == "2" ]
	then
		fs="f2fs"
		fs_pkg="f2fs-tools"
	elif [ "$fs_check" == "3" ]
	then
		fs="btrfs"
		fs_pkg="btrfs-progs"
	else
		exit 1
	fi
	echo ""
	echo "Do you want to enable luks2 encryption on your ROOT partition?"
	read -p "(y/n): " crypt
	if [ "$crypt" == "y" ] || [ "$crypt" == "Y" ]
	then
		crypt_partitioning
	else
		no_crypt_partitioning
	fi
}

### Installation & Configure the system ###
# Install essential packages & Fstab #
pacstrap_install() {
	pacman -Sy
	kernel="linux"
	pacstrap /mnt base $kernel linux-firmware $fs_pkg vim efibootmgr man man-db man-pages texinfo
	genfstab -U /mnt >> /mnt/etc/fstab
}

# Chroot #
# Generate chroot-install.sh for later use inside the chrooted environment
gen_chroot() {
	payload="#!/bin/sh
# Chroot helper script for the minimal Arch Linux installation script
# Installation steps from https://wiki.archlinux.org/title/Installation_guide

# Variables from initial script
console_keymap=\"$console_keymap\"
storage=\"$storage\"
root=\"$root\"
crypt=\"$crypt\"
crypt_open=\"$crypt_open\"
root_crypt=\"$root_crypt\"
kernel=\"$kernel\"


### Configure the system ###
# Time zone #
timezone() {
	#
	hwclock --systohc
}

# Localization #
locale() {
	echo \"Uncomment the # infront of your prefered locale and save.\"
	echo \"Ready?\"
	read -p \"(y/n): \" locale_check
	if [ \"rm-tslocale_check\" == \"y\" ] || [ \"rm-tslocale_check\" == \"Y\" ]
	then
		vim /etc/locale.gen
		locale-gen
		echo \"Example: en_US.UTF-8\"
		read -p \"Write your locale choise: \" locale
		echo \"LANG=\"rm-tslocale\"\" > /etc/locale.conf
		echo \"KEYMAP=\"rm-tsconsole_keymap\"\" > /etc/vconsole.conf
	else
		exit 1
	fi
}

# Network configuration #
systemd_net() {
	echo \"Do you want to enable systemd-networkd and systemd-resolved?\"
	read -p \"(y/n): \" systemd_net_check
	if [ \"rm-tssystemd_net_check\" == \"y\" ] || [ \"rm-tssystemd_net_check\" == \"Y\" ]
	then
		echo \"Do you want to use an ETHERNET or WIFI adapter?\"
		echo \"1. ETHERNET\"
		echo \"2. WIFI\"
		read adapter_check
		if [ \"rm-tsadapter_check\" == \"1\" ]
		then
			echo \"= = =\"
			ip link
			echo \"= = =\"
			echo \"\"
			read -p \"What is the name of your ETHERNET adapter: \" adapter
			echo \"[Match]
Name=rm-tsadapter

[Network]
DHCP=yes\" > /etc/systemd/network/20-wired.network
			systemctl enable systemd-networkd.service
			systemctl disable systemd-networkd-wait-online.service
			systemctl enable systemd-resolved.service
			ln -rsf /run/systemd/resolve/stub-resolve.conf /etc/resolv.conf
			timedatectl set-ntp true # only enable ntp if a internet connection can be established
		elif [ \"rm-tsadapter_check\" == \"2\" ]
		then
			echo \"= = =\"
			ip link
			echo \"= = =\"
			echo \"\"
			read -p \"What is the name of your WIFI adapter: \" adapter
			echo \"[Match]
Name=rm-tsadapter

[Network]
DHCP=yes
IgnoreCarrierLoss=3s\" > /etc/systemd/network/25-wireless.network
			systemctl enable systemd-networkd.service
			systemctl disable systemd-networkd-wait-online.service
			systemctl enable systemd-resolved.service
			ln -rsf /run/systemd/resolve/stub-resolve.conf /etc/resolv.conf
			timedatectl set-ntp true # only enable ntp if a internet connection can be established
			pacman -S iwd
		else
			echo \"You canceled the installation of systemd_net...\"
		fi

	else
		echo \"Okay...\"
	fi
}
hostname() {
	echo \"What's your prefered hostname?\"
	read hostname
	echo \"rm-tshostname\" > /etc/hostname
	echo \"127.0.0.1	localhost
::1		localhost
127.0.1.1	rm-tshostname\" > /etc/hosts
	# Root password #
	passwd
	systemd_net
}

# Initramfs #
# Generating a fresh initramfs is only requiered when using ecnryption.
# therefore it is included in the encrypted bootloader installation.

# Boot loader #
# Without encryption
no_crypt_bootloader() {
	bootctl install
	echo \"default  arch.conf
timeout  1
console-mode max
editor   no
\" > /boot/loader/loader.conf
	echo \"title   Arch Linux
linux   /vmlinuz-rm-tskernel
#initrd  /*-ucode.img
initrd  /initramfs-rm-tskernel.img
options root=/dev/rm-tsstoragerm-tsroot rw\" > /boot/loader/entries/arch.conf
	echo \"title   Arch Linux (fallback initramfs)
linux   /vmlinuz-rm-tskernel
#initrd  /*-ucode.img
initrd  /initramfs-rm-tskernel.img
options root=/dev/rm-tsstoragerm-tsroot rw\" > /boot/loader/entries/arch-fallback.conf
}
# With encryption
crypt_bootloader() {
	echo \"\"
	echo \"= = =\"
	blkid
	echo \"= = =\"
	echo \"\"
	echo \"What is the UUID of the cryptroot? Example /dev/sda's UUID, NOT! /dev/mapper/cryptroot\"
	read uuid
	bootctl install
	echo \"default  arch.conf
timeout  1
console-mode max
editor   no
\" > /boot/loader/loader.conf
	echo \"title   Arch Linux
linux   /vmlinuz-rm-tskernel
#initrd  /*-ucode.img
initrd  /initramfs-rm-tskernel.img
options root=/dev/rm-tsroot_crypt rd.luks.name=\"rm-tsuuid\"=rm-tscrypt_open rw\" > /boot/loader/entries/arch.conf
	echo \"title   Arch Linux (fallback initramfs)
linux   /vmlinuz-rm-tskernel
#initrd  /*-ucode.img
initrd  /initramfs-rm-tskernel.img
options root=/dev/rm-tsroot_crypt rd.luks.name=\"rm-tsuuid\"=rm-tscrypt_open rw\" > /boot/loader/entries/arch-fallback.conf
	echo \"\"
	echo \"Now you'll need to edit mkinitcpio.conf!\"
	echo \"You have to find the HOOKS section and add systemd, keyboard, sd-vconsole, sd-encrypt at the proper locations...\"
	echo \"Example: HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)\"
	echo \"Are you ready?\"
	read -p \"(y/n): \" hooks_check
	if [ \"rm-tshooks_check\" == \"y\" ] || [ \"rm-tshook_check\" == \"Y\" ]
	then
		vim /etc/mkinitcpio.conf
		mkinitcpio -P
	else	
		vim /etc/mkinitcpio.conf
		mkinitcpio -P
	fi
}
# Bootloader configuration
bootloader_configuration() {
	echo \"\"
	echo \"Do you want to install systemd-boot?\"
	read -p \"(y/n): \" bootloader_check
	if [ \"rm-tsbootloader_check\" == \"y\" ] || [ \"rm-tsbootloader_check\" == \"Y\" ]
	then
		if [ \"rm-tscrypt\" == \"y\" ] || [ \"rm-tscrypt\" == \"Y\" ]
		then
			crypt_bootloader
		else
			no_crypt_bootloader
		fi
	else
		echo \"Okay...\"
	fi
}

# Start of configuration script
echo \"\"
echo \"====================\"
echo \"\"
echo \"System configuration\"
echo \"\"
echo \"====================\"
echo \"\"

# Call the functions
timezone
locale
hostname
bootloader_configuration

# End
echo \"End of chroot script!\"
"
	echo "$payload" > ./chroot-install.sh
	sed -i -e 's/rm-ts/$/g' ./chroot-install.sh
	chmod +x ./chroot-install.sh
}
# Chroot install
chroot_install() {
	gen_chroot
	cp ./chroot-install.sh /mnt
	arch-chroot /mnt ./chroot-install.sh /bin/sh
}

# Start of installation script
echo ""
echo "==============================================================================="
echo ""
echo "Minimal Arch Linux installation script for later use with software like Ansible"
echo ""
echo "==============================================================================="
echo ""

echo "Requierments:"
echo "Make sure you have booted your system in EFI mode, and that you have completed"
echo "these installation steps from https://wiki.archlinux.org/title/Installation_guide"
echo "before running this script: Acquire an installation image & Verify signature &"
echo "Prepare an installation medium & Boot the live environment"
echo "Continue?"
read -p "(y/n): " requierments_check
if [ "$requierments_check" == "y" ] || [ "$requierments_check" == "Y" ]
then
	echo ""
else
	exit 1
fi

# Call the functions
console_keymap
sync_clock
partitioning_configuration
pacstrap_install
chroot_install

# Remove chroot-install.sh
rm /mnt/chroot-install.sh

# End
echo "End of installaion!"
