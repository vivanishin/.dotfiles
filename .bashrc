# .bashrc


# == TODO: refactor the functions into standalone scripts. ==
weather()
{
    curl "http://wttr.in/${1:-Moscow}"
}

up() {
    local cnt=${1:-1}
    local old_wd=$PWD
    while [ "$cnt" -gt 0 ]; do
            cnt=$((cnt - 1))
            cd ../
    done
    OLDPWD=$old_wd
}

# Cause gdb to reinitialize tui mode.
sigwinch()
{
  kill -SIGWINCH $(ps -u $(id -u) | grep gdb | awk '{print $1}' | tr '\n' ' ')
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

dotag()
{
  ctags -R &
  pid1=$!
  ctags -Re &
  pid2=$!
  cscope -bR &
  pid3=$!
  wait $pid1 $pid2 $pid3
  cscope-indexer -l -r
}

doautoconf()
{
  local old="$PWD"
  local bindir="/home/ivladak/inst/autoconf/bin"
  for subdir in "" "gcc" "libgomp" "libgfortran" "libiberty" "lto-plugin"
  do
    cd "/home/ivladak/src/gcc-gomp/$subdir" || echo "doautoconf: FAILed to cd" >&2
    $bindir/autoconf || echo "doautoconf: FAIL" >&2
  done
  cd "$old"
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

strace_wrapper_static=0
strace_wrapper()
{
  local options=(-yy -f -s 1024)
  local trace="-e trace=execve,vfork"
  (! echo $TRACE_OPTS | grep noenv > /dev/null) && options+=(-v)
  (echo $TRACE_OPTS | grep full > /dev/null) && trace="$trace,file,read,write,chdir,stat"

  options+=($trace)
  local logname="/tmp/strace-$strace_wrapper_static"
  options+=(-o "$logname" "$@")

  strace "${options[@]}"
  local retcode=$?

  strace_wrapper_static=$((strace_wrapper_static + 1))
  echo "$logname"
  strace-treeify "$logname"

  return $retcode
}

showfind()
{
    f_show=""
    f_grep_filenames=""
    f_print_command=""
    f_ignorecase=""
    f_color="--color=always"
    while [ $# -gt 0 ]
    do
        case $1 in
        -s | -sh | -sho | -show )
          f_show="yes"
          f_color="--color"
        ;;
        -f | -fi | -fil | -file | -filenames ) f_grep_filenames="yes" ;;
        -c | -cm | -cmd | -command ) f_print_command="yes" ;;
        -i ) f_ignorecase="-i" ;;
        * ) break ;;
        esac
        shift
    done
#    f_cmd='find . -name "*.[chCH]" -o -name "*.def" -o -name "*.in" -o -name "*.ac" -o -iname "*Make*" | '

    f_cmd="find . -type f -a -not -name '.*' -a -not -name 'cscope.out' -a -not -name 'tags' -a -not -name 'ccglue.out*' \
           -a -not -path './.git/*' -a -not -path '*/autom4te.cache/*' \
           -a -not -name 'configure' -a -not -name 'ChangeLog*' | "

    [ ! "x$f_grep_filenames" = "xyes" ] && f_cmd="$f_cmd xargs "

    f_cmd="$f_cmd grep $f_ignorecase -nH $f_color \"$1\" 2> /dev/null "

    [ "x$f_show" = "xyes" ] && f_cmd="$f_cmd | awk -F: '{ print \"less \" \"+\" \$2 \" -N \" \$1  }' | sh -"

    if [ "x$f_print_command" = "xyes" ]
    then
        echo "$f_cmd"
        return
    fi

    eval $f_cmd
}

unalias gsh > /dev/null 2>&1
gsh()
{
  git show ${@-HEAD}
}

# Print names of all the functions and defined macros in the C source file
# given it follows the GNU coding style conventions.
outline()
{
  sed -n '/^\([a-zA-Z0-9_:]\{1,\}\) (/p' $@  | awk '{ print $1 }' | sort -u
  echo "--"
  sed -n '/^[[:space:]]\{0,\}#define[[:space:]]\{0,\}\([a-zA-Z0-9_:]\{1,\}\)(/p' $@ \
    | awk -F'[( \t]' '{ print $2 }' | sort -u
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
. /home/ivladak/inst/z/z.sh

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
            /home/ivladak/S/shell \
            /home/ivladak/inst/git-browse/bin \
            /home/ivladak/inst/bin \
            /home/vlad/bin
do
  if [ -d $path ] && [ ! -w "$path" ] \
     && (! echo $PATH | egrep "($path:|$path/:|$path$)" > /dev/null 2>&1)
  then
    PATH=$path:$PATH
  fi
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
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias L='less -R'

alias j='jobs'
alias v='vim'
alias vi='vim'
alias e='emacsclient'
alias ec='emacsclient -c'
alias et='emacsclient -t'

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

alias cdd='cd `pwd`'
alias qwer='cd /home/ivladak/src/gcc-gomp'
alias bd="$EDITOR ~/src/build-default.sh"
alias rc="$EDITOR ~/.bashrc"
alias rcre=". ~/.bashrc"

alias ga='gdb --args'
alias oh='objdump -h'
alias trns="tr '\n' ' ' && echo"
alias trsn="tr ' ' '\n'"

alias phgrep='cat ~/.persistent_history|grep --color'
alias hgrep='history|grep --color'
alias psgrep="ps -A | grep "

alias crontab='crontab -i'
alias sshowfind='showfind -s'
alias mplayer='mplayer -af scaletempo'

alias def=sdcv

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
