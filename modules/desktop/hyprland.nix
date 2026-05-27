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
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
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

    # Screenshot + annotation + color picker
    grim
    slurp
    satty
    hyprpicker

    # Screen recording
    obs-studio
    gpu-screen-recorder

    # Clipboard
    wl-clipboard

    # Media
    mpv
    playerctl
    pavucontrol
    pamixer

    # Volume / brightness OSD
    swayosd

    # Brightness (used in keybinds)
    brightnessctl

    # Polkit agent
    polkit_gnome

    # Blue light filter
    hyprsunset

    # Browser
    chromium

    # File management
    nautilus
    gnome-disk-utility

    # Productivity
    libreoffice-fresh
    evince
    obsidian
    typora

    # Communication & notes
    signal-desktop
    localsend

    # Music
    spotify

    # Image viewer
    imv

    # Dev tools
    lazygit
    imagemagick

    # System info
    fastfetch

    # Calculator
    gnome-calculator

    # Misc Wayland utils
    wlr-randr
    libnotify
    swayimg
    btop

    # Video editing
    kdePackages.kdenlive

    # Theme packages (available system-wide for GTK/cursor/icon tooling)
    tokyonight-gtk-theme
    papirus-icon-theme
    bibata-cursors
  ];

  # ── Fonts ─────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ── Sound (pipewire already in laptops; ensure wireplumber is active) ─────
  services.pipewire.wireplumber.enable = true;

  # ── power-profiles-daemon ──────────────────────────────────────────────────
  services.power-profiles-daemon.enable = true;

  # ── User config: Hyprland, Waybar, Wofi, Mako ────────────────────────────
  home-manager.users.giovanni =
    let
      wallpaper = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/henrysipp/omarchy-nix/main/config/themes/wallpapers/1-Pawel-Czerwinski-Abstract-Purple-Blue.jpg";
        sha256 = "0n30217mf6nd400zzd8adn2p14k39dzllc9bqvwfsanj4ypghdls"; # pragma: allowlist secret
      };
    in
    {
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
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
            ];
            animation = [
              "global, 1, 10, default"
              "border, 1, 5.39, easeOutQuint"
              "windows, 1, 4.79, easeOutQuint"
              "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
              "windowsOut, 1, 1.49, linear, popin 87%"
              "fadeIn, 1, 1.73, almostLinear"
              "fadeOut, 1, 1.46, almostLinear"
              "fade, 1, 3.03, quick"
              "layers, 1, 3.81, easeOutQuint"
              "layersIn, 1, 4, easeOutQuint, fade"
              "layersOut, 1, 1.5, linear, fade"
              "fadeLayersIn, 1, 1.79, almostLinear"
              "fadeLayersOut, 1, 1.39, almostLinear"
              "workspaces, 0, 0, ease"
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
            force_split = 2;
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          ecosystem = {
            no_update_news = true;
          };

          "$mod" = "SUPER";

          bind = [
            # Terminal
            "$mod, Return, exec, ghostty"

            # Core
            "$mod, W, killactive"
            "$mod, Backspace, killactive"
            "$mod, Space, exec, wofi --show drun --sort-order=alphabetical"
            "$mod SHIFT, Space, exec, pkill -SIGUSR1 waybar"
            "$mod, V, togglefloating"
            "$mod, F, fullscreen"
            "$mod SHIFT, Plus, fullscreen"
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

            # Swap windows
            "$mod SHIFT, left,  swapwindow, l"
            "$mod SHIFT, right, swapwindow, r"
            "$mod SHIFT, up,    swapwindow, u"
            "$mod SHIFT, down,  swapwindow, d"

            # Workspaces — numbered
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

            # Workspaces — relative
            "$mod, comma,  workspace, -1"
            "$mod, period, workspace, +1"

            # Scroll through workspaces
            "$mod, mouse_down, workspace, e+1"
            "$mod, mouse_up,   workspace, e-1"

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

            # Screenshots
            ", Print,       exec, grim -g \"$(slurp)\" - | wl-copy"
            "SHIFT, Print,  exec, grim - | wl-copy"

            # Color picker
            "$mod, Print, exec, hyprpicker -a"
          ];

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          # Resize active window
          binde = [
            "$mod, minus,       resizeactive, -100 0"
            "$mod, equal,       resizeactive,  100 0"
            "$mod SHIFT, minus, resizeactive, 0 -100"
            "$mod SHIFT, equal, resizeactive, 0  100"
          ];

          # Works while locked
          bindel = [
            ", XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ", XF86MonBrightnessUp,   exec, brightnessctl -e4 -n2 set 5%+"
            ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
          ];

          bindl = [
            ", XF86AudioNext,  exec, playerctl next"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay,  exec, playerctl play-pause"
            ", XF86AudioPrev,  exec, playerctl previous"
          ];

          exec-once = [
            "mako"
            "hyprpaper"
            "hypridle"
            "hyprsunset"
            "swayosd-server"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          ];

          exec = [
            "pkill -SIGUSR2 waybar || waybar"
          ];

          windowrulev2 = [
            "float, class:pavucontrol"
            "float, class:nm-connection-editor"
            "float, class:blueman-manager"
            "float, class:org.gnome.Calculator"
            "float, class:com.mitchellh.ghostty, title:battery-info"
            "size 640 340, class:com.mitchellh.ghostty, title:battery-info"
            "suppressevent maximize, class:.*"
          ];

          windowrule = [
            "opacity 0.97 0.9, class:.*"
            "opacity 1 1, class:^(firefox)$, title:.*YouTube.*"
            "opacity 1 1, class:^(vlc|mpv)$"
            "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
          ];

          layerrule = [
            "blur,wofi"
            "blur,waybar"
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
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "bluetooth"
            "network"
            "wireplumber"
            "cpu"
            "power-profiles-daemon"
            "custom/battery-limit"
            "battery"
          ];

          "hyprland/workspaces" = {
            on-click = "activate";
            format = "{icon}";
            format-icons = {
              default = "";
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              active = "󱓻";
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
            };
          };
          clock = {
            format = "{:%A %I:%M %p}";
            format-alt = "{:%d %B W%V %Y}";
            tooltip = false;
          };
          cpu = {
            interval = 5;
            format = "󰍛";
            on-click = "ghostty -e btop";
          };
          battery = {
            interval = 5;
            format = "{capacity}% {icon}";
            format-discharging = "{icon}";
            format-charging = "{icon}";
            format-plugged = "";
            format-full = "Charged ";
            format-icons = {
              charging = [
                "󰢜"
                "󰂆"
                "󰂇"
                "󰂈"
                "󰢝"
                "󰂉"
                "󰢞"
                "󰂊"
                "󰂋"
                "󰂅"
              ];
              default = [
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
              ];
            };
            tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
            tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
            states = {
              warning = 20;
              critical = 10;
            };
            on-click = "ghostty --title=battery-info -e bash -c 'watch -n2 upower -i $(upower -e | grep -i bat | head -1)'";
          };
          "custom/battery-limit" = {
            interval = 5;
            exec = "cat /sys/class/power_supply/BAT1/charge_control_end_threshold 2>/dev/null";
            format = "{}% 󱐋";
            tooltip = true;
            tooltip-format = "Battery charge limit: {}% — click to toggle 80/100";
            on-click = "bash -c 'cur=$(cat /sys/class/power_supply/BAT1/charge_control_end_threshold); [ \"$cur\" -le 80 ] && echo 100 > /sys/class/power_supply/BAT1/charge_control_end_threshold || echo 80 > /sys/class/power_supply/BAT1/charge_control_end_threshold'";
          };
          network = {
            format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
            format = "{icon}";
            format-wifi = "{icon}";
            format-ethernet = "󰀂";
            format-disconnected = "󰖪";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            nospacing = 1;
            on-click = "nm-connection-editor";
          };
          bluetooth = {
            format = "󰂯";
            format-disabled = "󰂲";
            format-connected = "";
            tooltip-format = "Devices connected: {num_connections}";
            on-click = "blueman-manager";
          };
          wireplumber = {
            format = "";
            format-muted = "󰝟";
            scroll-step = 5;
            on-click = "pavucontrol";
            tooltip-format = "Playing at {volume}%";
            on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            max-volume = 150;
          };
          tray = { spacing = 13; };
          power-profiles-daemon = {
            format = "{icon}";
            tooltip-format = "Power profile: {profile}";
            tooltip = true;
            format-icons = {
              power-saver = "󰡳";
              balanced = "󰊚";
              performance = "󰡴";
            };
          };
        }];

        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 14px;
            border: none;
            border-radius: 0;
            min-height: 0;
          }
          window#waybar {
            background-color: rgba(26, 27, 38, 0.95);
            color: #c0caf5;
          }
          #workspaces button {
            all: initial;
            padding: 2px 6px;
            margin-right: 3px;
            color: #565f89;
          }
          #workspaces button.active {
            color: #7aa2f7;
          }
          #workspaces button:hover {
            color: #c0caf5;
          }
          #clock, #cpu, #battery, #network, #bluetooth,
          #wireplumber, #tray, #power-profiles-daemon,
          #custom-battery-limit {
            background-color: transparent;
            min-width: 12px;
            margin-right: 13px;
            color: #c0caf5;
          }
          #battery.warning  { color: #e0af68; }
          #battery.critical { color: #f7768e; }
          #bluetooth.connected { color: #7aa2f7; }
          #custom-battery-limit { color: #565f89; }
          #custom-battery-limit.charging { color: #9ece6a; }
        '';
      };

      # ── Mako notifications ──────────────────────────────────────────────────
      services.mako = {
        enable = true;
        settings = {
          background-color = "#1a1b26";
          text-color = "#c0caf5";
          border-color = "#787c99";
          progress-color = "#7aa2f7";
          width = 420;
          height = 110;
          padding = "10";
          margin = "10";
          border-size = 2;
          border-radius = 0;
          anchor = "top-right";
          layer = "overlay";
          default-timeout = 5000;
          ignore-timeout = false;
          max-visible = 5;
          sort = "-time";
          group-by = "app-name";
          actions = true;
          format = "<b>%s</b>\\n%b";
          markup = true;
          font = "JetBrainsMono Nerd Font 9";
        };
      };

      # ── Wofi launcher ───────────────────────────────────────────────────────
      programs.wofi = {
        enable = true;
        settings = {
          width = 600;
          height = 350;
          location = "center";
          show = "drun";
          prompt = "Search...";
          filter_rate = 100;
          allow_markup = true;
          no_actions = true;
          halign = "fill";
          orientation = "vertical";
          content_halign = "fill";
          insensitive = true;
          allow_images = true;
          image_size = 40;
          gtk_dark = true;
        };
        style = ''
          * {
            font-family: 'JetBrainsMono Nerd Font', monospace;
            font-size: 18px;
          }
          window {
            margin: 0px;
            padding: 20px;
            background-color: #1a1b26;
            opacity: 0.95;
          }
          #inner-box {
            margin: 0;
            padding: 0;
            border: none;
            background-color: #1a1b26;
          }
          #outer-box {
            margin: 0;
            padding: 20px;
            border: none;
            background-color: #1a1b26;
          }
          #scroll {
            margin: 0;
            padding: 0;
            border: none;
            background-color: #1a1b26;
          }
          #input {
            margin: 0;
            padding: 10px;
            border: none;
            background-color: #1a1b26;
            color: #c0caf5;
          }
          #input:focus {
            outline: none;
            box-shadow: none;
            border: none;
          }
          #text {
            margin: 5px;
            border: none;
            color: #cbccd1;
          }
          #entry {
            background-color: #1a1b26;
          }
          #entry:selected {
            outline: none;
            border: none;
          }
          #entry:selected #text {
            color: #2f3549;
          }
          #entry image {
            -gtk-icon-transform: scale(0.7);
          }
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
              timeout = 330;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
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
          window-padding-x = 14;
          window-padding-y = 14;
          window-decoration = "none";
          keybind = [ "ctrl+k=reset" ];
        };
      };

      xdg.configFile."hypr/hyprpaper.conf".text = ''
        splash = false
        preload = ${wallpaper}
        wallpaper = ,${wallpaper}
      '';

      # ── Hyprlock ─────────────────────────────────────────────────────────────
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            disable_loading_bar = true;
            no_fade_in = false;
          };
          auth = {
            fingerprint.enabled = true;
          };
          background = {
            monitor = "";
            path = wallpaper;
          };
          input-field = {
            monitor = "";
            size = "600, 100";
            position = "0, 0";
            halign = "center";
            valign = "center";
            inner_color = "rgb(47, 53, 73)";
            outer_color = "rgb(192, 202, 245)";
            outline_thickness = 4;
            font_family = "JetBrainsMono Nerd Font";
            font_size = 32;
            font_color = "rgb(192, 202, 245)";
            placeholder_color = "rgb(120, 124, 153)";
            placeholder_text = "  Enter Password 󰈷 ";
            check_color = "rgba(158, 206, 106, 1.0)";
            fail_text = "Wrong";
            rounding = 0;
            shadow_passes = 0;
            fade_on_empty = false;
          };
          label = {
            monitor = "";
            text = "$FPRINTPROMPT";
            text_align = "center";
            color = "rgb(192, 202, 245)";
            font_size = 24;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, -100";
            halign = "center";
            valign = "center";
          };
        };
      };
    };
}
