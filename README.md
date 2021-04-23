# cvm-arch
Arch Linux install script for CollabVM

# How to use
First, you will need to boot into the Arch Live CD.
One of the ways you could achieve this is to boot into netboot.xyz by going into the iPXE shell and typing `dhcp ; chain -a http://boot.netboot.xyz` and choosing Linux Network Installers > Arch Linux > whatever only option it gives.

Once you boot into the Live CD, type the commands:
```
curl -LJk http://gg.gg/cvm-arch -o a
chmod +x a
./a
```
Now it will ask you for the disk. Usually it is `/dev/sda`, sometimes `/dev/vda`.

After you enter the disk path, the script will continue automatically. Pay attention while it formats partitions: the formatting utility may ask you about whether to continue, because it sees a partition already. Choose yes (type `y`).

While it is installing Arch, try to protect the VM. I put some protections in, but, apparently, they don't work sometimes (example: pressing `ctrl-c` while in pacstrap may lead to an unfinished install and a bricked VM; in that case it would only be useful to vote reset the VM).

After it reboots, you have an Arch install. The `root` user doesn't have a password, and neither does the `user` account. The `user` account is added into the `/etc/sudoers` file to have a no-password access.
