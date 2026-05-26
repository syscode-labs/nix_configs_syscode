{ config, pkgs, lib, ... }:

{
  # ── Hyprland compositor ───────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ── Display manager: greetd + tuigreet ───────────────────────────────────
  # Disable the LightDM default that xserver.enable brings in
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;

  # Move kernel console to tty12 just before greetd starts so boot messages
  # are visible throughout boot but never overlap the login screen.
  systemd.services.console-to-tty12 = {
    description = "Redirect kernel console to tty12 before login screen";
    before = [ "greetd.service" ];
    wantedBy = [ "greetd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "redirect-console" ''
        ${pkgs.python3}/bin/python3 -c 'import fcntl,os,termios; fd=os.open("/dev/tty12",os.O_RDWR|os.O_NOCTTY); fcntl.ioctl(fd,termios.TIOCCONS); os.close(fd)'
        printf '\033c' > /dev/tty1
      '';
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd ${pkgs.writeShellScript "start-hyprland" ''
          printf '\033c' > /dev/tty1
          exec Hyprland
        ''}";
        user = "greeter";
      };
    };
  };

  # ── XDG portals ───────────────────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # ── Polkit authentication agent ──────────────────────────────────────────
  security.polkit.enable = true;

  # ── System packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Bar, launcher, notifications, wallpaper
    waybar
    wofi
    mako
    hyprpaper
    hyprlock
    hypridle

    # Screenshot
    grim
    slurp

    # Clipboard
    wl-clipboard

    # Media & audio control
    playerctl
    pavucontrol

    # Polkit agent
    polkit_gnome

    # Misc Wayland utils
    wlr-randr
    libnotify
    swayimg

    # Nerd font for bar glyphs
    nerd-fonts.jetbrains-mono
  ];

  # ── Sound (pipewire already in laptops; ensure wireplumber is active) ─────
  services.pipewire.wireplumber.enable = true;

  # ── User config: Hyprland, Waybar, Wofi, Mako ────────────────────────────
  home-manager.users.giovanni = {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = ",preferred,auto,1";

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
          "col.inactive_border" = "rgba(565f89aa)";
          layout = "dwindle";
        };

        decoration = {
          rounding = 8;
          blur = {
            enabled = true;
            size = 4;
            passes = 2;
          };
          shadow = {
            enabled = true;
            range = 6;
            render_power = 3;
          };
        };

        animations = {
          enabled = true;
          bezier = "ease, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 5, ease"
            "windowsOut, 1, 5, default, popin 80%"
            "border, 1, 8, default"
            "fade, 1, 5, default"
            "workspaces, 1, 4, default"
          ];
        };

        input = {
          kb_layout = "us";
          kb_variant = "intl";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-to-click = true;
          };
          sensitivity = 0;
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        ecosystem = {
          no_update_news = true;
        };

        "$mod" = "SUPER";

        bind = [
          # Core
          "$mod, Return, exec, alacritty"
          "$mod, Q, killactive"
          "$mod, R, exec, wofi --show drun"
          "$mod, V, togglefloating"
          "$mod, F, fullscreen"
          "$mod, P, pseudo"
          "$mod, J, togglesplit"

          # Focus
          "$mod, left,  movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up,    movefocus, u"
          "$mod, down,  movefocus, d"
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          # Move windows
          "$mod SHIFT, left,  movewindow, l"
          "$mod SHIFT, right, movewindow, r"
          "$mod SHIFT, up,    movewindow, u"
          "$mod SHIFT, down,  movewindow, d"

          # Workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # Screenshot: selection → clipboard
          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
          "$mod, Print, exec, grim - | wl-copy"

          # Lock
          "$mod, Escape, exec, hyprlock"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        binde = [
          # Volume
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          # Brightness
          ", XF86MonBrightnessUp,   exec, brightnessctl set 10%+"
          ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
          # Media
          ", XF86AudioPlay,  exec, playerctl play-pause"
          ", XF86AudioNext,  exec, playerctl next"
          ", XF86AudioPrev,  exec, playerctl previous"
        ];

        exec-once = [
          "waybar"
          "mako"
          "hyprpaper"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        ];

        windowrulev2 = [
          "float, class:pavucontrol"
          "float, class:nm-connection-editor"
          "float, class:org.gnome.Calculator"
          "suppressevent maximize, class:.*"
        ];
      };
    };

    # ── Waybar ──────────────────────────────────────────────────────────────
    programs.waybar = {
      enable = true;
      settings = [{
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
        };
        "hyprland/window" = {
          max-length = 50;
        };
        clock = {
          format = "  {:%H:%M}";
          format-alt = "  {:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        battery = {
          states = { warning = 30; critical = 15; };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };
        network = {
          format-wifi = "  {essid}";
          format-ethernet = "  {ipaddr}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = { default = [ "" "" "" ]; };
          on-click = "pavucontrol";
        };
        tray = { spacing = 8; };
      }];

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 13px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }
        window#waybar {
          background-color: rgba(26, 27, 38, 0.92);
          color: #c0caf5;
        }
        #workspaces button {
          padding: 0 8px;
          color: #565f89;
          background: transparent;
        }
        #workspaces button.active {
          color: #7aa2f7;
          border-bottom: 2px solid #7aa2f7;
        }
        #workspaces button:hover {
          color: #c0caf5;
          background: rgba(122, 162, 247, 0.1);
        }
        #window { color: #9ece6a; }
        #clock     { color: #7dcfff; padding: 0 12px; }
        #battery   { padding: 0 10px; }
        #network   { padding: 0 10px; }
        #pulseaudio { padding: 0 10px; }
        #tray       { padding: 0 8px; }
        #battery.warning  { color: #e0af68; }
        #battery.critical { color: #f7768e; }
      '';
    };

    # ── Mako notifications ──────────────────────────────────────────────────
    services.mako = {
      enable = true;
      settings = {
        background-color = "#1a1b26";
        text-color = "#c0caf5";
        border-color = "#7aa2f7";
        border-radius = 8;
        border-size = 2;
        default-timeout = 5000;
        font = "JetBrainsMono Nerd Font 11";
        padding = "10,14";
        width = 360;
      };
    };

    # ── Wofi launcher ───────────────────────────────────────────────────────
    programs.wofi = {
      enable = true;
      settings = {
        width = 600;
        height = 400;
        location = "center";
        show = "drun";
        prompt = "  Search";
        filter_rate = 100;
        allow_markup = true;
        no_actions = true;
        insensitive = true;
        term = "alacritty";
      };
      style = ''
        window {
          background-color: #1a1b26;
          border: 2px solid #7aa2f7;
          border-radius: 12px;
        }
        #input {
          color: #c0caf5;
          background-color: #24283b;
          border: none;
          border-radius: 8px;
          margin: 8px;
          padding: 6px 12px;
        }
        #entry {
          color: #c0caf5;
          padding: 6px 12px;
          border-radius: 6px;
        }
        #entry:selected {
          background-color: #7aa2f7;
          color: #1a1b26;
        }
        #text { font-family: "JetBrainsMono Nerd Font"; }
      '';
    };

    # Hyprpaper minimal config (set a wallpaper later via hyprpaper.conf)
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      splash = false
    '';
  };
}
