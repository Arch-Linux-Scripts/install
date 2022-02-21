#!/bin/sh
# Chroot helper script for the minimal Arch Linux installation script
# Installation steps from https://wiki.archlinux.org/title/Installation_guide

# Variables from initial script
console_keymap="$console_keymap"
storage="$storage"
root="$root"
crypt="$crypt"
crypt_open="$crypt_open"
root_crypt="$root_crypt"
kernel="$kernel"


### Configure the system ###
# Time zone #
timezone() {
	#
	hwclock --systohc
}

# Localization #
locale() {
	echo "Uncomment the # infront of your prefered locale and save."
	echo "Ready?"
	read -p "(y/n): " locale_check
	if [ "$locale_check" == "y" ] || [ "$locale_check" == "Y" ]
	then
		vim /etc/locale.gen
		locale-gen
		echo "Example: en_US.UTF-8"
		read -p "Write your locale choise: " locale
		echo "LANG="$locale"" > /etc/locale.conf
		echo "KEYMAP="$console_keymap"" > /etc/vconsole.conf
	else
		exit 1
	fi
}

# Network configuration #
systemd_net() {
	echo "Do you want to enable systemd-networkd and systemd-resolved?"
	read -p "(y/n): " systemd_net_check
	if [ "$systemd_net_check" == "y" ] || [ "$systemd_net_check" == "Y" ]
	then
		echo "Do you want to use an ETHERNET or WIFI adapter?"
		echo "1. ETHERNET"
		echo "2. WIFI"
		read adapter_check
		if [ "$adapter_check" == "1" ]
		then
			echo "= = ="
			ip link
			echo "= = ="
			echo ""
			read -p "What is the name of your ETHERNET adapter: " adapter
			echo "[Match]
Name=$adapter

[Network]
DHCP=yes" > /etc/systemd/network/20-wired.network
			systemctl enable systemd-networkd.service
			systemctl disable systemd-networkd-wait-online.service
			systemctl enable systemd-resolved.service
			ln -rsf /run/systemd/resolve/stub-resolve.conf /etc/resolv.conf
			timedatectl set-ntp true # only enable ntp if a internet connection can be established
		elif [ "$adapter_check" == "2" ]
		then
			echo "= = ="
			ip link
			echo "= = ="
			echo ""
			read -p "What is the name of your WIFI adapter: " adapter
			echo "[Match]
Name=$adapter

[Network]
DHCP=yes
IgnoreCarrierLoss=3s" > /etc/systemd/network/25-wireless.network
			systemctl enable systemd-networkd.service
			systemctl disable systemd-networkd-wait-online.service
			systemctl enable systemd-resolved.service
			ln -rsf /run/systemd/resolve/stub-resolve.conf /etc/resolv.conf
			timedatectl set-ntp true # only enable ntp if a internet connection can be established
			pacman -S iwd
		else
			echo "You canceled the installation of systemd_net..."
		fi

	else
		echo "Okay..."
	fi
}
hostname() {
	echo "What's your prefered hostname?"
	read hostname
	echo "$hostname" > /etc/hostname
	echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname" > /etc/hosts
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
	echo "default  arch.conf
timeout  1
console-mode max
editor   no
" > /boot/loader/loader.conf
	echo "title   Arch Linux
linux   /vmlinuz-$kernel
#initrd  /*-ucode.img
initrd  /initramfs-$kernel.img
options root=/dev/$storage$root rw" > /boot/loader/entries/arch.conf
	echo "title   Arch Linux (fallback initramfs)
linux   /vmlinuz-$kernel
#initrd  /*-ucode.img
initrd  /initramfs-$kernel.img
options root=/dev/$storage$root rw" > /boot/loader/entries/arch-fallback.conf
}
# With encryption
crypt_bootloader() {
	echo ""
	echo "= = ="
	blkid
	echo "= = ="
	echo ""
	echo "What is the UUID of the cryptroot? Example /dev/sda's UUID, NOT! /dev/mapper/cryptroot"
	read uuid
	bootctl install
	echo "default  arch.conf
timeout  1
console-mode max
editor   no
" > /boot/loader/loader.conf
	echo "title   Arch Linux
linux   /vmlinuz-$kernel
#initrd  /*-ucode.img
initrd  /initramfs-$kernel.img
options root=/dev/$root_crypt rd.luks.name="$uuid"=$crypt_open rw" > /boot/loader/entries/arch.conf
	echo "title   Arch Linux (fallback initramfs)
linux   /vmlinuz-$kernel
#initrd  /*-ucode.img
initrd  /initramfs-$kernel.img
options root=/dev/$root_crypt rd.luks.name="$uuid"=$crypt_open rw" > /boot/loader/entries/arch-fallback.conf
	echo ""
	echo "Now you'll need to edit mkinitcpio.conf!"
	echo "You have to find the HOOKS section and add systemd, keyboard, sd-vconsole, sd-encrypt at the proper locations..."
	echo "Example: HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)"
	echo "Are you ready?"
	read -p "(y/n): " hooks_check
	if [ "$hooks_check" == "y" ] || [ "$hook_check" == "Y" ]
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
	echo ""
	echo "Do you want to install systemd-boot?"
	read -p "(y/n): " bootloader_check
	if [ "$bootloader_check" == "y" ] || [ "$bootloader_check" == "Y" ]
	then
		if [ "$crypt" == "y" ] || [ "$crypt" == "Y" ]
		then
			crypt_bootloader
		else
			no_crypt_bootloader
		fi
	else
		echo "Okay..."
	fi
}

# Start of configuration script
echo ""
echo "===================="
echo ""
echo "System configuration"
echo ""
echo "===================="
echo ""

# Call the functions
timezone
locale
hostname
bootloader_configuration

# End
echo "End of chroot script!"
