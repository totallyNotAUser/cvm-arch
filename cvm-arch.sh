#!/bin/sh

echo [***]     Arch Linux installer by totallyNotAUser     [***]
echo [***] made specifically for CollabVM virtual machines [***]

read -p "[?] Enter disk: " diskdev

echo [*] Disabling ctrl-c and ctrl-alt-del
trap '' SIGINT
systemctl mask ctrl-alt-del.target
for i in {2..6}; do
    systemctl mask getty@tty${i}.service
done

timedatectl set-ntp true

echo [*] Detecting disk size
diskdev_size_bytes=$(blockdev --getsize64 ${diskdev})
diskdev_size=$(( $diskdev_size_bytes/1024/1024/1024 )) # in gigabytes
echo [*] Detected: ${diskdev_size}G
if [[ $diskdev_size -lt 10 ]]; then
    mainpart_size="$diskdev_size"
    echo [*] Using configuration: ${mainpart_size}G main partition, no swap
else
    mainpart_size=$(( $diskdev_size-8 ))
    echo [*] Using configuration: ${mainpart_size}G main partition, ${swap_size}G swap
fi

echo [*] Partitioning the disk
fdisk "$diskdev" << EOF
o
n
p
1

+${mainpart_size}G
n
p
2


t
2
swap
w
EOF

echo [*] Making filesystems
mkfs.ext4 "${diskdev}1"
mkswap "${diskdev}2"

echo [*] Mounting filesystems
mount "${diskdev}1" /mnt
swapon "${diskdev}2"

echo [*] Pacstrapping
pacstrap /mnt base linux grub sudo dhcpcd nano

echo [*] Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo [*] Entering stage 2
cat > /mnt/stage2.sh << EOF
echo [***] Stage 2 started [***]

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
grub-install --target=i386-pc ${diskdev}
grub-mkconfig -o /boot/grub/grub.cfg

echo [*] Enabling services
systemctl enable dhcpcd
EOF
chmod +x /mnt/stage2.sh
arch-chroot /mnt /stage2.sh

echo [*] Finished stage 2
rm /mnt/stage2.sh
echo [*] Rebooting
reboot
