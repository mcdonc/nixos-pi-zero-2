{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    ./sd-image.nix
    ./common-aarch64.nix
  ];

  sdImage = {
    compressImage = false;
    imageName = "fe127cb3.img";

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
      ### usb gadget
      dtoverlay=dwc2;
    };
  };

  # this is handled by nixos-hardware on Pi 4
  boot = {
    kernelParams = [
      "console=ttyS1,115200n8"
    ];
    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "libcomposite"
    ];
  };

  networking.hostName = "fe127cb3";
  hardware.raspberry-pi."4".dwc2.enable = true;

  networking = {
    hosts = {
      "127.0.0.1" = [ "fe127cb3.local" ];
      "10.213.0.1" = [ "fe127cb3.local" ];
    };
    interfaces.usb0.ipv4.addresses = [
      {
        address = "10.213.0.1";
        prefixLength = 24;
      }
    ];
  };

  networking.dhcpcd.denyInterfaces = [ "usb0" ];

  services.dhcpd4 = {
    enable = true;
    interfaces = [ "usb0" ];
    extraConfig = ''
      option domain-name "domain.mobile";
      option subnet-mask 255.255.255.0;
      option broadcast-address 10.213.0.255;
      option domain-name-servers 9.9.9.9, 1.1.1.1;
      option routers 10.213.0.1;
      subnet 10.213.0.0 netmask 255.255.255.0 {
        range 10.213.0.100 10.213.0.200;
      }
    '';
  };

  systemd.services."usb-otg" = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "default.target" ];
    script = ''
      mkdir -p /sys/kernel/config/usb_gadget/fe127cb3
      cd /sys/kernel/config/usb_gadget/fe127cb3
      echo 0x1d6b > idVendor # Linux Foundation
      echo 0x0104 > idProduct # Multifunction Composite Gadget
      echo 0x0100 > bcdDevice # v1.0.0
      echo 0x0200 > bcdUSB # USB2
      echo 0xEF > bDeviceClass
      echo 0x02 > bDeviceSubClass
      echo 0x01 > bDeviceProtocol
      mkdir -p /sys/kernel/config/usb_gadget/fe127cb3/strings/0x409
      echo "fedcba9876543211" > strings/0x409/serialnumber
      echo "TheWifiNinja" > strings/0x409/manufacturer
      echo "PI4 USB Device" > strings/0x409/product
      mkdir -p /sys/kernel/config/usb_gadget/fe127cb3/configs/c.1/strings/0x409
      echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
      echo 250 > configs/c.1/MaxPower
      # Add functions here
      # see gadget configurations below
      # End functions
      mkdir -p /sys/kernel/config/usb_gadget/fe127cb3/functions/ecm.usb0
      HOST="00:dc:c8:f7:75:14" # "HostPC"
      SELF="00:dd:dc:eb:6d:a1" # "BadUSB"
      echo $HOST > functions/ecm.usb0/host_addr
      echo $SELF > functions/ecm.usb0/dev_addr
      ln -s functions/ecm.usb0 configs/c.1/
      udevadm settle -t 5 || :
      ls /sys/class/udc > UDC
    '';
  };
  systemd.services.dhcpd4.after = [ "usb-otg.service" ];
  systemd.services."network-addresses-usb0".after = [ "usb-otg.service" ];


  services.dnsmasq.enable = true;

    # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

  # ! Change the following configuration
  users.users.giezac = {
    isNormalUser = true;
    home = "/home/giezac";
    description = "Me";
    extraGroups = ["wheel" "networkmanager" "gpio" "audio"];
    # ! Be sure to put your own public key here
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZawwmpdesq0ZvtXTdPekpjK3OYiPONrKO0no625FqYG8A8fZY++cxjG4my6HgmoaBrZiWvRJTa0WfTfw9Tzx9xt/FKrCB4bk9G33WP+RJNF7AEo3wkGGBLHzxp9bnhzzxdJOQCV67DRDxQNjMiR5S/bkSU+QYPDq+MLLx8mFz8lfzOSThVgDLjOj7lsRAJcrFDawsjZYHjsVBdDfCkjXGPKT7/c90k0BOvOjnOZ4vEn1w2s/Neq0rDTJYDUSmu9SzW/+WkM1rZa4GS5QGFMJVrI1Ow3X8tiUYpAp1oa0MyIpRkpuP39W+I6qaRBW4/+lyJYWsLP09hU7K2wT6OGap cool"
      ];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # ! Be sure to change the autologinUser.
  services.getty.autologinUser = "giezac";

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    htop
    vim
    usbutils
    k3s_1_26
    ethtool
  ];

}
