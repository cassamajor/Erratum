#!/usr/bin/env bash

# Ensure script is called with root privileges
[[ $UID == 0 ]] || { echo "You must be root to run this."; exit 1; }

create_paths() {
    REPO_DIR="$(pwd)"
    KICKSTART_DIR="$REPO_DIR/kickstart"
    UNATTENDED_DIR="$KICKSTART_DIR/unattended"
    MNT_DIR="$KICKSTART_DIR/mnt/"
    BOOT_CFG="$KICKSTART_DIR/boot_cfg/"

    mkdir -p {"$UNATTENDED_DIR","$MNT_DIR","$BOOT_CFG"}
}

define_filenames() {
    # './' preserves file structure when using rsync. These files are used for EFI boot.
    ISOLINUX_CFG="$UNATTENDED_DIR/./isolinux/isolinux.cfg"
    GRUB_CFG="$UNATTENDED_DIR/./EFI/BOOT/grub.cfg"
    EFIBOOT_IMG="$UNATTENDED_DIR/./images/efiboot.img"
    KS_CFG="$REPO_DIR/./ks.cfg"

    # Directory paths
    PILLAR="$REPO_DIR/pillar"
    SALT="$REPO_DIR/salt"
    STATES="$REPO_DIR/states"

    # ISO Filenames
    OFFICIAL_ISO="$KICKSTART_DIR/CentOS-7-x86_64-Minimal.iso"
    CUSTOM_ISO="$REPO_DIR/centos-7-custom.iso"
}

dl_image() {
    # Download CentOS ISO Image
    wget -NP $KICKSTART_DIR "http://buildlogs.centos.org/rolling/7/isos/x86_64/CentOS-7-x86_64-Minimal.iso"
}

mac_kickstart_config() {
    # Add Custom Menu Item
    gsed -i '/menu default/d' "$ISOLINUX_CFG"
    gsed -i -E 's/(.*)(hd:LABEL=\S+)(.*)/\1\2 inst.ks=\2:\/ks.cfg\3/' "$ISOLINUX_CFG"
    gsed -i -E 's/(.*)(hd:LABEL=\S+)(.*)/\1\2 inst.ks=\2:\/ks.cfg\3/' "$GRUB_CFG"
    gsed -i -E 's/set default=.*/set default="0"/' "$GRUB_CFG"
}

linux_kickstart_config() {
    # Add Custom Menu Item
    sed -i '/menu default/d' "$ISOLINUX_CFG"
    sed -i -E 's/(.*)(hd:LABEL=\S+)(.*)/\1\2 inst.ks=\2:\/ks.cfg\3/' "$ISOLINUX_CFG"
    sed -i -E 's/(.*)(hd:LABEL=\S+)(.*)/\1\2 inst.ks=\2:\/ks.cfg\3/' "$GRUB_CFG"
    sed -i -E 's/set default=.*/set default="0"/' "$GRUB_CFG"
}

mac_mount_image() {
    # Mount Centos 7 Image
    DEVICE=( $(hdiutil attach -nomount "$OFFICIAL_ISO") )
    mount -t cd9660 "$DEVICE" "$MNT_DIR"

    # Copy Contents of Image
    rsync -azh --info=progress2 "$MNT_DIR" "$UNATTENDED_DIR"
    umount "$MNT_DIR"
    hdiutil detach "$DEVICE"

    mac_kickstart_config
    DEVICE=( $(hdiutil attach -nomount "$EFIBOOT_IMG") )
    mount -t msdos "$DEVICE" "$MNT_DIR"
    rsync -azh --info=progress2 -R "$GRUB_CFG" "$MNT_DIR"
    umount "$MNT_DIR"
    hdiutil detach "$DEVICE"
}

linux_mount_image() {
    # Mount Centos 7 Image
    mount -t iso9660 -o loop $OFFICIAL_ISO "$MNT_DIR"

    # Copy Contents of Image
    rsync -azh --info=progress2 "$MNT_DIR" "$UNATTENDED_DIR"
    umount "$MNT_DIR"

    linux_kickstart_config
    mount -t vfat -o loop "$EFIBOOT_IMG" "$MNT_DIR"
    rsync -azh --info=progress2 -R "$GRUB_CFG" "$MNT_DIR"
    umount "$MNT_DIR"
}

build_custom_iso() {
    # Delete $CUSTOM_ISO if it exists
    if [ -f "$CUSTOM_ISO" ]; then
        rm -rf "$CUSTOM_ISO"
    fi

    # Transfer files required to boot into $BOOT_CFG
    rsync -azh --info=progress2 -R {"$ISOLINUX_CFG","$GRUB_CFG","$EFIBOOT_IMG","$KS_CFG"} "$BOOT_CFG"

    # Build Custom ISO Image
    xorriso -indev "$OFFICIAL_ISO" -boot_image any replay -map "$BOOT_CFG" / -map "$PILLAR" /pillar -map "$SALT" /salt -map "$STATES" /states -outdev "$CUSTOM_ISO"
}

main() {
    PS3="Select an option: "
    select options in "Run for Mac" "Run for Linux" "Exit"; do
        case "$options" in

            "Run for Mac" )
                create_paths
                define_filenames
                dl_image
                mac_mount_image
                build_custom_iso
                break;;

            "Run for Linux" )
                create_paths
                define_filenames
                dl_image
                linux_mount_image
                build_custom_iso
                break;;

            "Exit" )
                break;;
        esac
    done
}

main