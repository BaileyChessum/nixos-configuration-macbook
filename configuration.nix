# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let 
  waylandUrl = "https://github.com/nix-community/nixpkgs-wayland/archive/master.tar.gz";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./nixfiles/nixos
      "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/apple/t2"
    ];

  nix.settings.keep-outputs = true;

  nix.settings.substituters = [
    "https://cuda-maintainers.cachix.org"
    "https://ros.cachix.org"
    "https://hyprland.cachix.org"
    "https://cache.nixos.org/"
    "https://nixpkgs-wayland.cachix.org"
    "https://cache.soopy.moe"
    "https://hydra.novarover.space"
  ];

  nix.settings.trusted-substituters = [
    "https://cuda-maintainers.cachix.org"
    "https://ros.cachix.org"
    "https://hyprland.cachix.org"
    "https://cache.nixos.org/"
    "https://nixpkgs-wayland.cachix.org"
    "https://cache.soopy.moe"
    "https://hydra.novarover.space"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
    "nova-1:lRJ8YVtMKF5G7fk1OUx4vFyupTCwA4RrMNTX4JH7Hig="
  ];

  nixpkgs.overlays = [
    #(import "${(builtins.fetchTarball waylandUrl)}/overlay.nix")
    (import ./overlays/zoom-us-fix.nix)
  ];
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;

  boot.loader = {
    efi.efiSysMountPoint = "/boot";
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  #networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME desktop environment
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Disable wayland
  services.xserver.displayManager.gdm.wayland = lib.mkForce false;

  services.xserver.videoDrivers = [ "modesetting" ];

  # Nova profile configuration
  nova.profile = "shared";
  nova.substituters.nova.password = import ./hydra-secret.nix; 
  home-manager.sharedModules = [{
    home.stateVersion = "23.05";
  }];
  home-manager.backupFileExtension = "backup";

  # Customize
  home-manager.users.nova = {
    home.packages = with pkgs; [
      #add your software here
      #e.g. slack
      slack
      brave  
      obsidian
      zoom-us
      discord
      blackbox-terminal
      jetbrains.pycharm-professional
      jetbrains.webstorm
      obs-studio
      prismlauncher
    ];

    # Adding to the task bar
    dconf.settings."org/gnome/shell".favorite-apps = [
      "brave-browser.desktop"
      "slack.desktop"
      "com.raggesilver.BlackBox.desktop"
      "obsidian.desktop"
    ];

    # Adds HiDPI scaling support
    #dconf.settings."org/gnome/mutter".experimental-features = [ 
    #  "scale-monitor-framebuffer" 
    #];

    programs.git = lib.mkForce {
      enable = true;
      userName = "Bailey Chessum";
      userEmail = "bailey.chessum1@gmail.com";
    };
  };
  nova.desktop.browser.enable = lib.mkForce false;

  # --- Wayland --- #
  #environment.sessionVariables.NIXOS_OZONE_WL = "1";  # for chromium/electron
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
      ];
    };
  };

  # Suspend Workaround
  # https://wiki.t2linux.org/guides/postinstall/#suspend-workaround
  systemd.services.suspend-fix-t2 = {
    description = "Disable and Re-Enable Apple BCE Module (and Wi-Fi)";

    unitConfig = { 
      StopWhenUnneeded = "yes";
    };

    serviceConfig = { 
      User = "root";
      RemainAfterExit = "yes";

      # TODO: Do rmmod and modprobe need to be declaratively defined?
      ExecStart = "/run/current-system/sw/bin/rmmod -f apple-bce";
      ExecStop = "/run/current-system/sw/bin/modprobe apple-bce";
    };
 
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ]; 
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    # jack.enable = true;
  };

  hardware.pulseaudio.enable = false;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput = {
  #   enable = true;
  #   touchpad = {
  #     # Enable naturalScrolling in touchpads
  #     naturalScrolling = true;
  #   };
  #   touchpad = {
  #     # Only for mouse, set accel profile to flat
  #     accelProfile = "adaptive";
  #   };
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  #users.users.bailey = {
  #  isNormalUser = true;
  #  extraGroups = [ "networkmanager" "wheel" ]; # Enable ‘sudo’ for the user.
  #  packages = with pkgs; [
  #  ];
  #};

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [ # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  # ]; 

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}

