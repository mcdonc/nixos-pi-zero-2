{
  lib,
  pkgs,
  ...
}:
let
  breakonthru = pkgs.python3Packages.buildPythonPackage {
    pname="breakonthru";
    version="0.0";
    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "00854bd73404f449db0eb5b21da517c07cc617a7";
      sha256 = "sha256-52u9M05855AJ47Dk1+Fvc+VileaVsX6ClCdpn3N43eA=";
    };
  };
  python_with_packages = (pkgs.python311.withPackages (p:
    with p; [
      pkgs.python311Packages.rpi-gpio
      pkgs.python311Packages.gpiozero
      pkgs.python311Packages.pyserial
      pkgs.python311Packages.plaster-pastedeploy
      pkgs.python311Packages.pyramid
      pkgs.python311Packages.pyramid-chameleon
      pkgs.python311Packages.waitress
      pkgs.python311Packages.bcrypt
      pkgs.python311Packages.websockets
      pkgs.python311Packages.gpiozero
      pkgs.python311Packages.pexpect
      pkgs.python311Packages.setproctitle
      pkgs.python311Packages.requests
      pkgs.python311Packages.websocket-client
      pkgs.python311Packages.supervisor
      pkgs.python311Packages.pjsua2
      breakonthru
    ]));
in
{
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

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [pkgs.raspberrypiWirelessFirmware];

  users.groups.gpio = {};

  # services.udev.extraRules = ''
  #   SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio",MODE="0660"
  #   SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
  #   SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
  # '';

  # https://raspberrypi.stackexchange.com/questions/40105/access-gpio-pins-without-root-no-access-to-dev-mem-try-running-as-root
  services.udev.extraRules = ''
    KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys/class/gpio && ${pkgs.coreutils}/bin/chmod -R g=u /sys/class/gpio'"
    SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys%p && ${pkgs.coreutils}/bin/chmod -R g=u /sys%p'"
  '';

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

    # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  # ! Change the following configuration
  users.users.chrism = {
    isNormalUser = true;
    home = "/home/chrism";
    description = "Chris McDonough";
    extraGroups = ["wheel" "networkmanager" "gpio"];
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
    libraspberrypi
    raspberrypi-eeprom
    htop
    vim
    emacs
    ripgrep
    btop
    python_with_packages
    usbutils
    tmux
    git
    lsof
    bat
    alsa-utils # aplay
    dig
    tree
    bintools
    file
    ethtool
    minicom
    pjsip
    # asterisk
  ];


}
