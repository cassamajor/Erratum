#!/usr/bin/env bash

# Ensure script is called with root privileges
if ! [[ "${EUID}" -eq 0 ]]; then
  echo "Please re-run script with root privileges"
  exit 1
fi

REPO_DIR="$(pwd)"
KICKSTART_DIR="$REPO_DIR/kickstart"
UNATTENDED_DIR="$KICKSTART_DIR/unattended"
MNT_DIR="$KICKSTART_DIR/mnt/"

mkdir -p "$UNATTENDED_DIR"
mkdir -p "$MNT_DIR"

cd "$KICKSTART_DIR"
PS3="Select an option: "
select disk in "Run for Mac" "Run for Linux" "Exit"; do
    case $disk in
        "Run for Mac" )
# Download CentOS ISO Image
wget -N "http://buildlogs.centos.org/rolling/7/isos/x86_64/CentOS-7-x86_64-Minimal.iso"

# Mount Centos 7 Image
DEVICE=( $(hdiutil attach -nomount $KICKSTART_DIR/CentOS-7-x86_64-Minimal.iso) )
mount -t cd9660 "$DEVICE" "$MNT_DIR"

# Copy Contents of Image
rsync -av "$MNT_DIR" "$UNATTENDED_DIR"
umount "$MNT_DIR"
hdiutil detach "$DEVICE"

# Kickstart Configuration
cp "$REPO_DIR/anaconda-ks.cfg" "$UNATTENDED_DIR/ks.cfg"

# Add Custom Menu Item
gsed -i '/menu default/d' "$UNATTENDED_DIR/isolinux/isolinux.cfg"
gsed -i '/label linux/i \
label is\
  menu label ^Kickstart\
  menu default\
  kernel vmlinuz\
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 inst.ks=cdrom:/dev/cdrom:/ks.cfg\
  ' "$UNATTENDED_DIR/isolinux/isolinux.cfg"

# Build Custom ISO Image
wget -N https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar -xzvf syslinux-6.03.tar.gz

cd "$UNATTENDED_DIR/"
cp -rp $REPO_DIR/errata "$(pwd)"
xorriso -as mkisofs -o "$REPO_DIR/centos-7-custom.iso" -b isolinux/isolinux.bin -isohybrid-mbr "$KICKSTART_DIR/syslinux-6.03/bios/mbr/isohdpfx.bin" -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -J -R -v -V 'CentOS 7 x86_64' "$(pwd)"
break;;

        "Run for Linux" )
# Download CentOS ISO Image
wget -N "http://buildlogs.centos.org/rolling/7/isos/x86_64/CentOS-7-x86_64-Minimal.iso"

# Mount Centos 7 Image
mkdir "$MNT_DIR"
mount -o loop CentOS-7-x86_64-Minimal.iso "$MNT_DIR"

# Copy Contents of Image
rsync -av "$MNT_DIR" "$UNATTENDED_DIR"
umount "$MNT_DIR"

# Kickstart Configuration
cp "$REPO_DIR/anaconda-ks.cfg" "$UNATTENDED_DIR/isolinux/ks.cfg"

# Add Custom Menu Item
sed -i '/menu default/d' "$UNATTENDED_DIR/isolinux/isolinux.cfg"
sed -i '/label linux/i \
label is\
  menu label ^Kickstart\
  menu default\
  kernel vmlinuz\
  append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 inst.ks=hd:LABEL=CentOS\\x207\\x20x86_64:/isolinux/ks.cfg\
  ' "$UNATTENDED_DIR/isolinux/isolinux.cfg"

# Build Custom ISO Image
wget -N https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar -xzvf syslinux-6.03.tar.gz

cd "$UNATTENDED_DIR/"
cp -rp $REPO_DIR/errata "$(pwd)"
xorriso -as mkisofs -o "$REPO_DIR/centos-7-custom.iso" -b isolinux/isolinux.bin -isohybrid-mbr "$KICKSTART_DIR/syslinux-6.03/bios/mbr/isohdpfx.bin" -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -isohybrid-gpt-basdat -J -R -v -V 'CentOS 7 x86_64' "$(pwd)"
break;;

        "Exit" ) break;;
    esac
done