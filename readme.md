# Usage
The strategy of dotfiles management I use is described
[here](https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/)
(inspired by [this](https://news.ycombinator.com/item?id=11070797) hn post).

In short, all you need to start using these dotfiles is:
```
cd
git clone --bare --recurse-submodules https://github.com/ivladak/.dotfiles.git
alias config='git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'
config checkout
config submodule update --init --recursive --remote # a hack: `checkout --recurse-submodules' should work, but doesn't seem to
```

# TODO:
- fix emacsclient stuff and mb start the daemon in xinitrc
- [bash]: ^C -> save the command in history with prepended '#'
- rcre should be able to reload bashrc for all tmux sessions
- non-renamed (e.g. "1","2",...) tmux session killer
    mb reap once an hour all detached non-renamed sections which have been
    inactive for a while
