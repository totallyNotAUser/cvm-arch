#!/bin/sh

echo [***]     Arch Linux installer by totallyNotAUser     [***]
echo [***] made specifically for CollabVM virtual machines [***]

echo [*] Autodetecting disk
[[ -e /dev/sda ]] && diskdev="/dev/sda"
[[ -e /dev/vda ]] && diskdev="/dev/vda"
[[ "$diskdev" == "" ]] && read -p "[?] Failed to autodetect, enter disk: " diskdev
echo [*] Using $diskdev as disk

echo [*] Installing CollabNet certificate
curl http://192.168.1.1/ca.crt -o ca.crt
trust anchor ca.crt

echo [*] Disabling ctrl-c and ctrl-alt-del
trap '' 2
trap '' 9
trap '' 15
systemctl mask ctrl-alt-del.target

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
    echo [*] Using configuration: ${mainpart_size}G main partition
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
while true; do
    pacstrap /mnt base linux grub sudo dhcpcd nano && break || echo [!] Failed pacstrap, retrying
done

echo [*] Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo [*] Entering stage 2
while true; do
    {
        curl https://raw.githubusercontent.com/totallyNotAUser/cvm-arch/main/stage2.sh -o /mnt/stage2.sh
        chmod +x /mnt/stage2.sh
        arch-chroot /mnt /stage2.sh "$diskdev"
    } && break || echo [!] Failed to download stage 2, retrying
done

echo [*] Finished stage 2
rm /mnt/stage2.sh
echo [*] Rebooting
reboot
