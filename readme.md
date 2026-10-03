# Usage

Refer to https://github.com/vivanishin/manifest/blob/main/README.md

# Zoxide setup

Install the hook before zoxide so the initial package installation also checks
the reviewed Bash initialization cache:

```
~/.config/pacman/hooks/install-zoxide-init-cache-hook
sudo pacman -S --needed zoxide
```

# TODO:
- fix emacsclient stuff and mb start the daemon in xinitrc
- [bash]: ^C -> save the command in history with prepended '#'
- rcre should be able to reload bashrc for all tmux sessions
