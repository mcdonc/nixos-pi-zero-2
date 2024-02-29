{
  lib,
  modulesPath,
  pkgs,
  nixos-hardware,
  ...
}:
{
  imports = [
    ./sd-image.nix
    "${nixos-hardware}/raspberry-pi/4"
    ./common.nix
  ];

  sdImage = {
    compressImage = false;
    imageName = "pi4.img";

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

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };

  networking = {
    interfaces.end0.useDHCP = true;
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
    hostName = "locknix";
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


}
