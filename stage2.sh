#!/bin/sh

echo [***] Stage 2 started [***]

echo [*] Installing CollabNet certificate
curl http://192.168.1.1/ca.crt -o /ca.crt
trust anchor /ca.crt

echo [*] Setting UTC timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo [*] Setting locale
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf

echo [*] Setting hostname
echo "vm" >> /etc/hostname
echo "127.0.0.1    localhost" >> /etc/hosts
echo "::1        localhost" >> /etc/hosts
echo "127.0.1.1    vm.localdomain vm" >> /etc/hosts

echo [*] Deleting root account password
passwd -d root

echo [*] Creating user account
useradd -m -G wheel -s /bin/bash user
passwd -d user
echo "%wheel ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo [*] Installing a bootloader called GRUB, the Grand Unified one
grub-install --target=i386-pc $1
grub-mkconfig -o /boot/grub/grub.cfg

echo [*] Enabling services
systemctl enable dhcpcd
