
{ config, pkgs, lib, ... }:

let
  dotfiles = pkgs.fetchFromGitHub {
    owner = "jbial";
    repo = ".dotfiles";
    rev = "master"; # or commit
    sha256 = "N7z9c63mhrr2hLklgmv38bWF8ZTDE6V1G4qgaLKycUI=";
  };
in {
  home.username = "tycho";
  home.homeDirectory = "/home/tycho";
  home.file = {
    ".vimrc".source = "${dotfiles}/.vimrc";
    ".tmux.conf".source = "${dotfiles}/.tmux.conf";
    ".config/ghostty".source = "${dotfiles}/.config/ghostty";
    ".config/nvim".source    = "${dotfiles}/.config/nvim";
  };

  home.packages = with pkgs; [
    home-manager
    tmux
    btop
    neofetch
    uv
  ];

  home.pointerCursor = {
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ";
    size = 24;
    x11.enable = true;
    gtk.enable = true;
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };
    initContent = ''
      export EDITOR=vim
      export TERM=xterm-256color
      export UV_PYTHON_DOWNLOADS=never
      bindkey '^J' down-line-or-history  # Ctrl + J for down
      bindkey '^K' up-line-or-history    # Ctrl + K for up
      bindkey '^H' backward-word    # Ctrl + H for previous word
      bindkey '^L' forward-word    # Ctrl + L for next word 
      if [ -t 1 ]; then
        neofetch
      fi
    '';
  };
  programs.git = {
    enable = true;
    userName = "Jeffrey Lai";
    userEmail = "jlai@utexas.edu";
  };
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-beta;
    policies.Homepage.StartPage = "https://nixos.org";
    policies.DisableTelemetry = true;
  };

  # startup ssh agent and add pkeys
  services.ssh-agent.enable = true;
  systemd.user.services."ssh-add-all" = {
    Unit = {
      Description = "Add all SSH private keys to ssh-agent";
      After = [ "ssh-agent.service" ];
      Wants = [ "ssh-agent.service" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
      ExecStart = pkgs.writeShellScript "ssh-add-all" ''
        shopt -s nullglob
        for k in "$HOME"/.ssh/id_*; do
          [[ "$k" == *.pub ]] && continue
          ${pkgs.openssh}/bin/ssh-add -q "$k" || true
        done
      '';
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.setupDotfiles = lib.hm.dag.entryAfter ["installPackages"] ''
    echo "Running dotfile setup..."
    PATH=${pkgs.git}/bin:${pkgs.vim}/bin:$PATH
    ${pkgs.bash}/bin/bash ${dotfiles}/setup.sh
  '';

  home.stateVersion = "25.05";
}
