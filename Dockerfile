ARG OS_IMAGE=registry.opensuse.org/opensuse/tumbleweed
ARG OS_VERSION=latest


FROM ${OS_IMAGE}:${OS_VERSION} AS os

RUN zypper --non-interactive removerepo repo-update && zypper ref
RUN zypper --non-interactive --gpg-auto-import-keys install --no-recommends -- \
      patterns-base-base \
      aaa_base-extras \
      acl \
      chrony \
      dracut \
      fipscheck \
      iputils \
      issue-generator \
      vim-small \
      less \
      parted \
      gptfdisk \
      iproute2 \
      openssh \
      rsync \
      dosfstools \
      lsof \
      ignition \
      combustion \
      grub2-branding-openSUSE \
      grub2-x86_64-efi \
      shim \
      kernel-default \
      btrfsprogs \
      btrfsmaintenance \
      snapper \
      podman \
      git-core \
      NetworkManager \
      systemd \
      systemd-default-settings-branding-SLE && \
    zypper clean --all

# Install EFI binaries at /boot/efi/EFI/BOOT
RUN mkdir -p /boot/efi/EFI/BOOT && \
    cp /usr/share/efi/x86_64/MokManager.efi /boot/efi/EFI/BOOT/ && \
    cp /usr/share/efi/x86_64/shim.efi /boot/efi/EFI/BOOT/bootx64.efi && \
    cp /usr/share/grub2/x86_64-efi/grub.efi /boot/efi/EFI/BOOT/

# Install grub2 fonts
RUN mkdir -p /boot/grub2/fonts && \
    cp /usr/share/grub2/unicode.pf2 /boot/grub2/fonts

# Generate initrd and kernel and initrd links
RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && \
    dracut -f --no-hostonly "/boot/initrd-${kernel##/boot/vmlinuz-}" "${kernel##/boot/vmlinuz-}" && \
    ln -s "/boot/initrd-${kernel##/boot/vmlinuz-}" /boot/initrd && \
    ln -sf "${kernel}" /boot/vmlinuz

# Set default parameters for grub2
RUN echo 'GRUB_GFXMODE=auto'                  >> /etc/default/grub && \
    echo 'GRUB_TERMINAL_INPUT="console"'      >> /etc/default/grub && \
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"'     >> /etc/default/grub && \
    echo 'SUSE_BTRFS_SNAPSHOT_BOOTING=true'   >> /etc/default/grub

# Include grub setup. Ideally this could be substituted by a grub2-mkconfig call
# but I could not manage to get it working inside the container neither in a chroot
# enviroment as part of the builder.sh script
COPY grub.cfg /boot/grub2/grub.cfg
COPY early-grub.cfg /boot/efi/EFI/BOOT/grub.cfg

# Copying it to /root as this is a RW volume, handy for debugging and hacking
COPY updater.sh /root/updater.sh

CMD ["/bin/bash"]
