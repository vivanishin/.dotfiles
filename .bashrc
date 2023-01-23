# .bashrc

up() {
    local cnt=${1:-1}
    local old_wd=$PWD
    while [ "$cnt" -gt 0 ]; do
            cnt=$((cnt - 1))
            cd ../
    done
    OLDPWD=$old_wd
}

cpath()
{
    realpath "${1:-.}" | tee >(cat 1>&2) | xclip -in -selection clipboard
}

dr()
{
    cd "$(dirname "$(realpath "$1")")"
}

e()
{
    emacsclient "$@" & disown
}

ec()
{
    e -c "$@"
}

# Create a fresh temp directory for today and copy its name to the clipboard.
# cd there if an argument is passed.
tmp()
{
    dir=/tmp/$(date +%m-%d)
    echo "$dir"
    if $(which xclip &>/dev/null); then
        printf " $dir " | xclip -in -selection clipboard
    fi
    mkdir -p $dir
    [ -n "$1" ] && cd "$dir"
}

# Kill all background processes of this shell except for the given space-separated list.
killexcept()
{
  IFS=' ' local except=" $* "
  local tmpfile=/tmp/killer-$$

  # We cannot use a pipe here, because disowning won't work since some context
  # will not be the same inside the pipe. So we use a temp file.
  jobs | awk -F '[\]\[]' '{ print $2 }' > $tmpfile 2> /dev/null
  while read jobnum
  do
    case "$except" in
        *" $jobnum "* )
          # not killing $jobnum
          ;;
        *)
          kill "%$jobnum"
          disown "%$jobnum"
          ;;
    esac
  done < $tmpfile 2> /dev/null
  rm $tmpfile
}

dounset()
{
  unset LIBRARY_PATH
  unset COLLECT_GCC
  unset COLLECT_LTO_WRAPPER
  unset OFFLOAD_TARGET_NAMES
  unset COMPILER_PATH
  unset COLLECT_GCC_OPTIONS
}

unalias gsh > /dev/null 2>&1
gsh()
{
  git show ${@-HEAD}
}

ansi_colored()
{
    local text="$1"
    local color="$2"
    local start="\[\033[01;${color}m\]"
    local end="\[\033[00m\]"
    printf "%s%s%s" "$start" "$text" "$end"
}

# See http://eli.thegreenplace.net/2013/06/11/keeping-persistent-history-in-bash
# for details.
#
# Note, HISTTIMEFORMAT has to be set and end with at least one space; for
# example:
#
#   export HISTTIMEFORMAT="%F %T  "
#
# If your format is set differently, you'll need to change the regex that
# matches history lines below.

log_bash_persistent_history()
{
  [[
    $(history 1) =~ ^\ *[0-9]+\ +([^\ ]+\ [^\ ]+)\ +(.*)$
  ]]
  local date_part="${BASH_REMATCH[1]}"
  local command_part="${BASH_REMATCH[2]}"
  if [ "$command_part" != "$PERSISTENT_HISTORY_LAST" ]
  then
    echo $date_part "|" "$command_part" >> ~/.persistent_history
    export PERSISTENT_HISTORY_LAST="$command_part"
  fi
}

# Stuff to do on PROMPT_COMMAND
run_on_prompt_command()
{
    log_bash_persistent_history
}

path_remove_dups()
{
  echo $1 | awk -F: '
  {
    result = ""
    for (i = 1; i <= NF; i++)
      if (!seen[$i]) {
        seen[$i] = 1
        result = result ":" $i
      }
    print result
  } ' | sed -e 's|:\{0,\}\(.*\):\{0,\}|\1|'
}

PROMPT_COMMAND="run_on_prompt_command"
export HISTTIMEFORMAT="%F %T  "

# This should go after other modifications of PROMPT_COMMAND (or these other
# modifications should append rather that rewrite the variable).
. /home/vlad/bin/z/z.sh

# Source global definitions
if [ -f /etc/bashrc ]; then
       . /etc/bashrc
fi

export PATH=$(path_remove_dups $PATH)

# User specific aliases and functions
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export EDITOR=vim
export ALTERNATE_EDITOR=""
export LSCOLORS="ExGxcxdxCxegedabagacad"
export CLICOLOR=YES

export LD_LIBRARY_PATH=/home/ivladak/inst/lib:/usr/lib64:$HOME/local/lib64

for path in /opt/cuda-7.0.18RC/bin \
	    ~/bin
do
  [ ! -e "$path" ] && continue
  echo $PATH | grep -Eq "($path:|$path/:|$path$)" && continue
  PATH=$PATH:$path
done
export PATH

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=15000
HISTFILESIZE=20000
# only ignore duplicates, do not ignore space-prefixed commands
HISTCONTROL=ignoredups

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Assume we have colorful terminal. (Else use this: PS1='[\u@\h \W]\$ ')
PS1="$(ansi_colored '\u@\h' 32)"
PS1="$PS1$(ansi_colored '\w' 34)\$ "


# TODO: look for another way to test that ls and grep have the --color option
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='grep -E --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias L='less -R'
alias tre='pstree -apl | less'

alias j='jobs'
alias v='vim'
alias vi='vim'

alias ta='tmux a -t'
alias td='tmux detach'
alias tn='tmux new-session -s'
alias tls='tmux ls'

alias gs='git status'
alias gsn='git status --untracked=no'
alias gl='git log'
alias gd='git diff'
alias amend='git commit --amend'
alias gds='git diff --staged'
alias gsd='git diff --staged'
alias config='git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'

alias cdd='cd `pwd`'
alias qwer='cd /home/ivladak/src/gcc-gomp'
alias bd="$EDITOR ~/bin/build-default.sh"
alias rc="$EDITOR ~/.bashrc"
alias svim="sudo -E $EDITOR"
alias rcre=". ~/.bashrc"

alias ga='gdb --args'
alias oh='objdump -h'
alias re='readelf -aW'
alias trns="tr '\n' ' ' && echo"
alias trsn="tr ' ' '\n'"

alias phgrep='cat ~/.persistent_history|grep --color'
alias hgrep='history|grep --color'
alias psgrep="ps -A | grep "

alias crontab='crontab -i'
alias sshowfind='showfind -s'
alias mplayer='mplayer -af scaletempo'
alias fej='find . -type f -print0 -iname \*.jpg -o -iname \*.jpeg | sort -z | xargs -0 feh -Z --auto-rotate --scale-down'
alias clip="xclip -in -selection clipboard"

alias def=sdcv
alias ]=xdg-open

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

IGNOREEOF=3

if ps -ef | grep tmux | grep $(id -un) | grep -v grep > /dev/null
then
    tmux ls
fi

. ~/.bashrc-teach
if [ -f ~/.bashrc-local ]; then
    . ~/.bashrc-local
fi
