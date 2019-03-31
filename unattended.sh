#!/usr/bin/env bash

# Ensure script is called with root privileges
[[ $UID == 0 ]] || { echo "You must be root to run this."; exit 1; }

create_paths() {
    REPO_DIR="$(pwd)"
    KICKSTART_DIR="$REPO_DIR/kickstart"
    UNATTENDED_DIR="$KICKSTART_DIR/unattended"
    MNT_DIR="$KICKSTART_DIR/mnt/"

    mkdir -p "$UNATTENDED_DIR"
    mkdir -p "$MNT_DIR"

    cd "$KICKSTART_DIR"
}

dl_image() {
    # Download CentOS ISO Image
    wget -N "http://buildlogs.centos.org/rolling/7/isos/x86_64/CentOS-7-x86_64-Minimal.iso"
}

mac_mount_image() {
    # Mount Centos 7 Image
    DEVICE=( $(hdiutil attach -nomount $KICKSTART_DIR/CentOS-7-x86_64-Minimal.iso) )
    mount -t cd9660 "$DEVICE" "$MNT_DIR"

    # Copy Contents of Image
    rsync -azh --info=progress2 "$MNT_DIR" "$UNATTENDED_DIR"
    umount "$MNT_DIR"
    hdiutil detach "$DEVICE"
}

linux_mount_image() {
    # Mount Centos 7 Image
    mount -o loop CentOS-7-x86_64-Minimal.iso "$MNT_DIR"

    # Copy Contents of Image
    rsync -azh --info=progress2 "$MNT_DIR" "$UNATTENDED_DIR"
    umount "$MNT_DIR"
}

mac_kickstart_config() {
    # Kickstart Configuration
    cp "$REPO_DIR/anaconda-ks.cfg" "$UNATTENDED_DIR/ks.cfg"

    # Add Custom Menu Item
    gsed -i '/menu default/d' "$UNATTENDED_DIR/isolinux/isolinux.cfg"
    gsed -i '/label linux/i \
    label is\
      menu label ^Automated Installation of Erratum\
      menu default\
      kernel vmlinuz\
      append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 inst.ks=hd:LABEL=CentOS\\x207\\x20x86_64:/ks.cfg\
      ' "$UNATTENDED_DIR/isolinux/isolinux.cfg"
    gsed -i '/install/i \
    menuentry "Automated Installation of Erratum" --class fedora --class gnu-linux --class gnu --class os {\
      linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 quiet inst.ks=hd:LABEL=CentOS\\x207\\x20x86_64:/ks.cfg\
      initrdefi /images/pxeboot/initrd.img\
    }
      ' "$UNATTENDED_DIR/EFI/BOOT/grub.cfg"
}

linux_kickstart_config() {
    # Kickstart Configuration
    cp "$REPO_DIR/anaconda-ks.cfg" "$UNATTENDED_DIR/ks.cfg"

    # Add Custom Menu Item
    sed -i '/menu default/d' "$UNATTENDED_DIR/isolinux/isolinux.cfg"
    sed -i '/label linux/i \
    label is\
      menu label ^Kickstart\
      menu default\
      kernel vmlinuz\
      append initrd=initrd.img inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 inst.ks=hd:LABEL=CentOS\\x207\\x20x86_64:/ks.cfg\
      ' "$UNATTENDED_DIR/isolinux/isolinux.cfg"
    sed -i '/install/i \
    menuentry "Automated Installation of Erratum" --class fedora --class gnu-linux --class gnu --class os {\
      linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS\\x207\\x20x86_64 quiet inst.ks=hd:LABEL=CentOS\\x207\\x20x86_64:/ks.cfg\
      initrdefi /images/pxeboot/initrd.img\
    }
      ' "$UNATTENDED_DIR/EFI/BOOT/grub.cfg"
}

build_custom_iso() {
    # Build Custom ISO Image
    wget -N https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
    tar -xzf syslinux-6.03.tar.gz

    cd "$UNATTENDED_DIR/"
    cp -rp $REPO_DIR/errata "$(pwd)"
    xorriso -as mkisofs -o "$REPO_DIR/centos-7-custom.iso" -b isolinux/isolinux.bin -isohybrid-mbr "$KICKSTART_DIR/syslinux-6.03/bios/mbr/isohdpfx.bin" -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -J -R -v -V 'CentOS 7 x86_64' "$(pwd)"
}

main() {
    PS3="Select an option: "
    select options in "Run for Mac" "Run for Linux" "Exit"; do
        case "$options" in

            "Run for Mac" )
                create_paths
                dl_image
                mac_mount_image
                mac_kickstart_config
                build_custom_iso
                break;;

            "Run for Linux" )
                create_paths
                dl_image
                linux_mount_image
                linux_kickstart_config
                build_custom_iso
                break;;

            "Exit" )
                break;;
        esac
    done
}

main