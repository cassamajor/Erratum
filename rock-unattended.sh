#!/usr/bin/env bash

# Ensure script is called with root privileges
[[ $UID == 0 ]] || { echo "You must be root to run this."; exit 1; }

REPO_DIR="$(pwd)"
KICKSTART_DIR="$REPO_DIR/kickstart"
UNATTENDED_DIR="$KICKSTART_DIR/unattended"
MNT_DIR="$KICKSTART_DIR/mnt/"
ROCK_VERSION="rocknsm-2.2.0.iso"
ISO_LOCATION="https://download.rocknsm.io/$ROCK_VERSION"

mkdir -p "$UNATTENDED_DIR"
mkdir -p "$MNT_DIR"

cd "$KICKSTART_DIR"
PS3="Select an option: "
select disk in "Run for Mac" "Run for Linux" "Exit"; do
    case $disk in
        "Run for Mac" )
# Download CentOS ISO Image
wget -N "$ISO_LOCATION"

# Mount Centos 7 Image
DEVICE=( $(hdiutil attach -nomount $KICKSTART_DIR/$ROCK_VERSION) )
mount -t cd9660 "$DEVICE" "$MNT_DIR"

# Copy Contents of Image
rsync -azh --info=progress2 "$MNT_DIR" "$UNATTENDED_DIR"
umount "$MNT_DIR"
hdiutil detach "$DEVICE"

# Kickstart Configuration
sed -i '/selinux --enforcing/d' "$UNATTENDED_DIR/ks.cfg"
sed -i '/ks-post.log/i \
# Erratum No Chroot\
selinux --permissive\
%post --nochroot --log=/mnt/sysimage/root/erratum-nochroot.log\
rsync -rP /run/install/repo/errata/pillar /mnt/sysimage/srv/\
rsync -rP /run/install/repo/errata/{router,orch,files,top.sls} /mnt/sysimage/srv/states/\
rsync -rP /run/install/repo/errata/{master,minion} /mnt/sysimage/etc/salt/\
%end\
# End Erratum No Chroot
    ' "$UNATTENDED_DIR/ks.cfg"

sed -i '/ks-post-chroot.log/i \
# Erratum Chroot\
%post --log=/root/erratum-post.log\
yum install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm  -y\
yum install salt-master -y\
yum install salt-minion -y\
systemctl enable salt-master salt-minion\
systemctl start salt-master salt-minion\
systemctl enable sshd\
sudo yum update -y\
%end\
# End Erratum Chroot
    ' "$UNATTENDED_DIR/ks.cfg"

# Build Custom ISO Image
wget -N https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar -xzf syslinux-6.03.tar.gz

cd "$UNATTENDED_DIR/"
cp -rp $REPO_DIR/errata "$(pwd)"
xorriso -as mkisofs -o "$REPO_DIR/centos-7-custom.iso" -b isolinux/isolinux.bin -isohybrid-mbr "$KICKSTART_DIR/syslinux-6.03/bios/mbr/isohdpfx.bin" -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -J -R -v -V 'ROCK 2.2 x86_64' "$(pwd)"
break;;

        "Run for Linux" )
# Download ROCK_NSM ISO Image
wget -N "$ISO_LOCATION"

# Mount Centos 7 Image
mount -o loop $ROCK_VERSION "$MNT_DIR"

# Copy Contents of Image
rsync -azh --info=progress2 "$MNT_DIR" "$UNATTENDED_DIR"
umount "$MNT_DIR"

# Kickstart Configuration
sed -i '/selinux --enforcing/d' "$UNATTENDED_DIR/ks.cfg"
sed -i '/rootpw/a \
# Create privileged user\
user --groups=wheel --name=router --password=password --plaintext
' "$UNATTENDED_DIR/ks.cfg"
sed -i '/ks-post.log/i \
# Erratum No Chroot\
selinux --permissive\
%post --nochroot --log=/mnt/sysimage/root/erratum-nochroot.log\
rsync -rP /run/install/repo/errata/pillar /mnt/sysimage/srv/\
rsync -rP /run/install/repo/errata/{router,orch,files,top.sls} /mnt/sysimage/srv/states/\
rsync -rP /run/install/repo/errata/{master,minion} /mnt/sysimage/etc/salt/\
%end\
# End Erratum No Chroot\
    ' "$UNATTENDED_DIR/ks.cfg"

sed -i '/ks-post-chroot.log/i \
# Erratum Chroot\
%post --log=/root/erratum-post.log\
yum install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm  -y\
yum install salt-master -y\
yum install salt-minion -y\
systemctl enable salt-master salt-minion\
systemctl start salt-master salt-minion\
systemctl enable sshd\
sudo yum update -y\
%end\
# End Erratum Chroot\
    ' "$UNATTENDED_DIR/ks.cfg"

# Build Custom ISO Image
wget -N https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar -xzf syslinux-6.03.tar.gz

cd "$UNATTENDED_DIR/"
cp -rp $REPO_DIR/errata "$(pwd)"
xorriso -as mkisofs -o "$REPO_DIR/centos-7-custom.iso" -b isolinux/isolinux.bin -isohybrid-mbr "$KICKSTART_DIR/syslinux-6.03/bios/mbr/isohdpfx.bin" -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -isohybrid-gpt-basdat -J -R -v -V 'ROCK 2.2 x86_64' "$(pwd)"
break;;

        "Exit" ) break;;
    esac
done
