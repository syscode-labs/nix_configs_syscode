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

  # Suppress runtime kernel messages (USB, etc.) from appearing over the greeter.
  # Errors and above still reach tty12 via the redirect below.
  boot.consoleLogLevel = 3;

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
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --width 60 --greeting \"titan\" --theme \"border=#7aa2f7;text=#c0caf5;prompt=#bb9af7;time=#7dcfff;action=#9ece6a;button=#7aa2f7;container=#1a1b26;input=#c0caf5\" --cmd ${pkgs.writeShellScript "start-hyprland" ''
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

  # ── Bluetooth manager ─────────────────────────────────────────────────────
  services.blueman.enable = true;

  # ── System packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Bar, launcher, notifications, wallpaper
    waybar
    wofi
    mako
    hyprpaper
    hyprlock
    hypridle

    # Terminal
    ghostty

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
    btop

    # Nerd font for bar glyphs
    nerd-fonts.jetbrains-mono

    # Theme packages (available system-wide for GTK/cursor/icon tooling)
    tokyonight-gtk-theme
    papirus-icon-theme
    bibata-cursors
  ];

  # ── Sound (pipewire already in laptops; ensure wireplumber is active) ─────
  services.pipewire.wireplumber.enable = true;

  # ── User config: Hyprland, Waybar, Wofi, Mako ────────────────────────────
  home-manager.users.giovanni = {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        # 1.56667x scale recommended by Hyprland for Framework 13 2256×1504
        monitor = ",preferred,auto,1.56667";

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(7aa2f7ee) rgba(bb9af7ee) 45deg";
          "col.inactive_border" = "rgba(565f89aa)";
          layout = "dwindle";
        };

        decoration = {
          rounding = 4;
          blur = {
            enabled = true;
            size = 5;
            passes = 2;
            vibrancy = 0.1696;
          };
          shadow = {
            enabled = false;
          };
        };

        animations = {
          enabled = true;
          bezier = [
            "easeOutQuint, 0.23, 1, 0.32, 1"
            "easeInOutCubic, 0.65, 0.05, 0.35, 0.95"
            "linear, 0, 0, 1, 1"
          ];
          animation = [
            "windows, 1, 4, easeOutQuint, slide"
            "windowsOut, 1, 4, easeOutQuint, slide"
            "border, 1, 5, easeOutQuint"
            "fade, 1, 2, linear"
            "workspaces, 1, 4, easeInOutCubic, slide"
          ];
        };

        input = {
          kb_layout = "us";
          kb_variant = "intl";
          kb_options = "compose:caps";
          repeat_rate = 40;
          repeat_delay = 250;
          numlock_by_default = true;
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-to-click = true;
            clickfinger_behavior = true;
            scroll_factor = 0.4;
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
          # Core — omarchy-style bindings
          "$mod, Return, exec, ghostty"
          "$mod, W, killactive"
          "$mod, Space, exec, wofi --show drun"
          "$mod, V, togglefloating"
          "$mod, F, fullscreen"
          "$mod, P, pseudo"
          "$mod, J, togglesplit"
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          # Session
          "$mod, Escape, exec, hyprlock"
          "$mod SHIFT, Escape, exit,"
          "$mod CTRL, Escape, exec, systemctl reboot"
          "$mod SHIFT CTRL, Escape, exec, systemctl poweroff"

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
          "hypridle"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        ];

        windowrulev2 = [
          "float, class:pavucontrol"
          "float, class:nm-connection-editor"
          "float, class:blueman-manager"
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
        height = 26;
        spacing = 0;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "cpu"
          "pulseaudio"
          "bluetooth"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
        };
        "hyprland/window" = {
          max-length = 60;
          separate-outputs = true;
        };
        clock = {
          format = "  {:%H:%M}";
          format-alt = "  {:%a %d %b}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        cpu = {
          format = "  {usage}%";
          interval = 2;
          on-click = "ghostty -e btop";
        };
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          on-click = "ghostty --initial-window-size-columns=80 --initial-window-size-rows=24 -e bash -c 'watch -n2 upower -i $(upower -e | grep -i bat | head -1)'";
        };
        network = {
          format-wifi = "  {essid}";
          format-ethernet = "  {ipaddr}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };
        bluetooth = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          on-click = "blueman-manager";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = { default = [ "" "" "" ]; };
          on-click = "pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        tray = { spacing = 8; };
      }];

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 10px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }
        window#waybar {
          background-color: rgba(26, 27, 38, 0.95);
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
        #window        { color: #9ece6a; padding: 0 8px; }
        #clock         { color: #7dcfff; padding: 0 12px; }
        #cpu           { color: #e0af68; padding: 0 10px; }
        #battery       { padding: 0 10px; }
        #network       { padding: 0 10px; }
        #bluetooth     { padding: 0 10px; }
        #pulseaudio    { padding: 0 10px; }
        #tray          { padding: 0 8px; }
        #battery.warning  { color: #e0af68; }
        #battery.critical { color: #f7768e; }
        #bluetooth.connected { color: #7aa2f7; }
      '';
    };

    # ── Mako notifications ──────────────────────────────────────────────────
    services.mako = {
      enable = true;
      settings = {
        background-color = "#1a1b26";
        text-color = "#c0caf5";
        border-color = "#7aa2f7";
        border-radius = 4;
        border-size = 2;
        default-timeout = 5000;
        font = "JetBrainsMono Nerd Font 9";
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
        term = "ghostty";
      };
      style = ''
        window {
          background-color: #1a1b26;
          border: 2px solid #7aa2f7;
          border-radius: 8px;
        }
        #input {
          color: #c0caf5;
          background-color: #24283b;
          border: none;
          border-radius: 6px;
          margin: 8px;
          padding: 6px 12px;
        }
        #entry {
          color: #c0caf5;
          padding: 6px 12px;
          border-radius: 4px;
        }
        #entry:selected {
          background-color: #7aa2f7;
          color: #1a1b26;
        }
        #text { font-family: "JetBrainsMono Nerd Font"; }
      '';
    };

    # ── hypridle ─────────────────────────────────────────────────────────────
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    # ── GTK theme ────────────────────────────────────────────────────────────
    gtk = {
      enable = true;
      theme = {
        name = "Tokyonight-Dark";
        package = pkgs.tokyonight-gtk-theme;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };
      font = {
        name = "Noto Sans";
        size = 9;
      };
    };

    # ── Qt theme (follows GTK) ────────────────────────────────────────────────
    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };

    # ── Cursor (Wayland + X11) ────────────────────────────────────────────────
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "24";
    };

    programs.ghostty = {
      enable = true;
      settings = {
        font-size = 10;
        background-opacity = 0.9;
      };
    };

    xdg.configFile."hypr/hyprpaper.conf".text =
      let
        wp = builtins.fetchurl {
          url = "https://raw.githubusercontent.com/henrysipp/omarchy-nix/main/config/themes/wallpapers/1-Pawel-Czerwinski-Abstract-Purple-Blue.jpg";
          sha256 = "0n30217mf6nd400zzd8adn2p14k39dzllc9bqvwfsanj4ypghdls"; # pragma: allowlist secret
        };
      in
      ''
        splash = false
        preload = ${wp}
        wallpaper = ,${wp}
      '';
  };
}
