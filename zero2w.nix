{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    ./sd-image.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";
  nixpkgs.buildPlatform.system = "x86_64-linux";
  # ! Need a trusted user for deploy-rs.
  nix.settings.trusted-users = ["@wheel"];
  system.stateVersion = "24.05";

  # don't build the NixOS docs locally
  documentation.nixos.enable = false;

  services.zram-generator = {
    enable = true;
    settings.zram0 = {
      compression-algorithm = "zstd";
      zram-size = "ram * 2";
    };
  };

  sdImage = {
    compressImage = false;
    imageName = "zero2.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;

      # Reduce allocation of VRAM to 16MB minimum for non-rotated
      # (32MB for rotated)
      gpu_mem = 16;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;
    };
  };

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [pkgs.raspberrypiWirelessFirmware];

  boot = {
    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      timeout = 2;
    };

    # https://artemis.sh/2023/06/06/cross-compile-nixos-for-great-good.html
    # for deploy-rs
    # binfmt.emulatedSystems = [ "x86_64-linux" ];

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set.
    # This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;
  };

  services.dnsmasq.enable = true;
  
  networking = {
    #interfaces."wlan0".useDHCP = true;
    interfaces.wlan0 = {
      ipv4.addresses = [
        {
          address = "192.168.1.171";
          prefixLength = 24;
        }
      ];
    };
    # dnsmasq reads /etc/resolv.conf to find 8.8.8.8 and 1.1.1.1
    nameservers =  [ "127.0.0.1" "8.8.8.8" "1.1.1.1"];
    useDHCP = false;
    dhcpcd.enable = false;
    defaultGateway = "192.168.1.1";
    hostName = "nixos-pi";
    firewall.enable = false;
    wireless = {
      enable = true;
      interfaces = ["wlan0"];
      # ! Change the following to connect to your own network
      networks = {
        "ytvid-rpi" = { # SSID
          psk = "ytvid-rpi"; # password
        };
      };
    };
  };

  # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  # ! Change the following configuration
  users.users.chrism = {
    isNormalUser = true;
    home = "/home/chrism";
    description = "Chris McDonough";
    extraGroups = ["wheel" "networkmanager"];
    # ! Be sure to put your own public key here
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
      ];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "chrism";

 environment.systemPackages = with pkgs; [
    htop
    vim
    # emacs
    # ripgrep
    # btop
    # (python311.withPackages (p:
    #   with p; [
    #     python311Packages.rpi-gpio
    #     python311Packages.gpiozero
    #     python311Packages.pyserial
    #   ]))
    # usbutils
    # tmux
    # git
    # dig
    # tree
    # bintools
    # lsof
    # pre-commit
    # file
    # bat
    # ethtool
    # minicom
    # fast-cli
    # nmap
    # openssl
    # dtc
    # zstd
    # neofetch
  ];

}
