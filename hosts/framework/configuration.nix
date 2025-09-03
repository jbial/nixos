{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "machine";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkb.options in tty.
  };

  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;

  fonts.fontDir.enable = true;
  fonts.packages = [ pkgs.nerd-fonts.zed-mono ];

  users.users.tycho = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      ghostty
      zsh
      neovim
      firefox
    ];
    shell = pkgs.zsh;
  };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    shell = pkgs.bashInteractive;
    extraGroups=[ "shadow" ];
  };
  users.groups.greeter = {};

  security.sudo.enable = true;
  security.pam.services = {
    login.fprintAuth = true;
    gdm.fprintAuth = true;
    sudo.fprintAuth = true;
    polkit-1.fprintAuth = true;
    greetd.fprintAuth = true;
  };

  environment.localBinInPath = true;
  environment.variables.EDITOR = "vim";
  environment.etc."greetd/environments/Hyprland".text = ''
    XDG_SESSION_TYPE=wayland
    XDG_SESSION_DESKTOP=Hyprland
  '';
  environment.systemPackages = with pkgs; [
    wl-clipboard
    tree
    git
    vim
    unzip
    jq
    tofi
    mako
    waybar
    brightnessctl
    pamixer
    wget
    curl
    hypridle
    hyprlock
    hyprpaper
    fprintd
    libfprint
  ];

  ### Program configurations
  programs.zsh.enable = true;

  # for proper python linking
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      zlib zstd stdenv.cc.cc curl openssl attr libssh bzip2 libxml2 acl libsodium util-linux xz systemd
    ];
  };

  ### Service configurations

  # enable fingerprint
  services.fprintd.enable = true;

  # suspend on lid close → then hibernate
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchExternalPower = "suspend-then-hibernate";
    lidSwitchDocked = "ignore";
  };
  systemd.sleep.extraConfig = ''
    SuspendState=mem
    HibernateDelaySec=15min
  '';

  # power / firmware
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;

  # wayland greetd login
  services.greetd.enable = true;
  services.greetd.settings.default_session = {
    command = ''
      ${pkgs.greetd.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --user-menu \
        --cmd "${pkgs.hyprland}/bin/Hyprland"
    '';
    user = "greeter";
  };

  systemd.services.greetd.serviceConfig = {
    # Let greetd see fingerprint devices
    SupplementaryGroups = [ "input" "video" ];
    Environment = [
      "XDG_RUNTIME_DIR=/run/user/1000"
      "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
    ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  # remap capslock to control
  services.libinput.enable = true;
  services.keyd.enable = true;
  services.keyd.keyboards.default = {
    ids = [ "*" ];
    settings = {
      main = {
        capslock = "layer(control)";
      };
    };
  };

  system.stateVersion = "25.05";
}

