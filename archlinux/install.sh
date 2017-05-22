#!/bin/sh
. "$1"

sfdisk /dev/sda << EOF
,,L
EOF

yes | mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt
timedatectl set-ntp true
fallocate -l ${SWAP_SIZE:-500M} /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

printf "Server = %s\n" ${MIRROR:-http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/$repo/os/$arch} | cat - /etc/pacman.d/mirrorlist > /tmp/mirrorlist
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
mv /tmp/mirrorlist /etc/pacman.d/mirrorlist

pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab
echo "/swapfile		none		swap	defaults	0 0" >> /mnt/etc/fstab
cp /tmp/install-chrooted.sh /mnt/root/
arch-chroot /mnt sh -ex /root/install-chrooted.sh
rm /mnt/root/install-chrooted.sh

sed \
  -e 's/^PermitRootLogin .*/PermitRootLogin no/' \
  -e 's/^#PubkeyAuthentication .*/PubkeyAuthentication yes/' \
  -e 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' \
  -e 's/^#UseDNS .*/UseDNS no/' /mnt/etc/ssh/sshd_config > /tmp/sshd_config
mv /tmp/sshd_config /mnt/etc/ssh/sshd_config

umount -R /mnt

reboot
