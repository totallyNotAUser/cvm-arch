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
curl https://raw.githubusercontent.com/totallyNotAUser/cvm-arch/main/stage2.sh -o /mnt/stage2.sh
chmod +x /mnt/stage2.sh
arch-chroot /mnt /stage2.sh

echo [*] Finished stage 2
rm /mnt/stage2.sh
echo [*] Rebooting
reboot
