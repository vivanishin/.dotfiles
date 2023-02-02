
# Login shell (from which dwm and transitively, qutebrowser descend) does not
# read ~/.bashrc; set the path here.
for path in ~/bin
do
    if [ ! -d "$path" ]; then
        continue
    fi
    if ! echo $PATH | grep -qw "$path"; then
        PATH=$PATH:$path
    fi
done
export PATH

if [ -f ~/.bashrc ]; then
   . ~/.bashrc
fi
