# .bashrc

# auto-update dotfiles from my git repo
cd ~/dotfiles
bash update.sh >/dev/null
cd - > /dev/null

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Enable color prompt and common color-aware aliases if the terminal supports it
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
else
    color_prompt=
fi

if [ -n "$force_color_prompt" ]; then
    color_prompt=yes
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;34m\]\w\[\e[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

export HISTSIZE=10000
export HISTFILESIZE=-1

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias emacs="emacs -nw"
alias move_contents='function _move() { local dir=$1; for f in $(ls -A | grep -v $dir); do mv "$f" "$dir"; done; }; _move'
alias howbig='du -sh {.,}* | sort -hr'
alias makeref='openssl rand -base64 32'
alias tab="cd /home/mcn26/project_pi_skr2/mcn26/tabula-rasa"
alias tabdat="cd /nfs/roberts/project/pi_skr2/shared/tabula_data"
alias bcluster="ssh mcn26@bouchet.ycrc.yale.edu"
alias cluster="ssh mcn26@login2.mccleary.ycrc.yale.edu"
alias hostinger="ssh root@srv1060410.hstgr.cloud"
alias arraystat="python3 ~/.jobsum.py"
alias octave="octave --no-gui"

hr() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: convert_to_hours <hours> <minutes>"
        return 1
    fi

    local hrs=$1
    local mins=$2

    # Use bc for floating point arithmetic
    local total=$(echo "scale=1; $hrs + ($mins / 60)" | bc)

    echo "$total"
}

alias protectmain="git config branch.main.pushRemote no-push"

cancel_all_but() {
    keep_id="$1"
    if [ -z "$keep_id" ]; then
        echo "Usage: cancel_all_but <jobid_to_keep>"
        return 1
    fi

    squeue -u "$USER" -h -o "%A" | grep -v "^${keep_id}$" | xargs -r scancel
}

function autocat() {
    if [[ -z "$1" ]]; then
        echo "Usage: autocat <filename>"
        return 1
    fi

    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found."
        return 1
    fi

    while true; do
        clear
        cat "$file"
        sleep 5
    done
}


function logs() {
grep -rh "^\[[^]]\]" "${1:-.}" . | python3 ~/.logsort.py
}

function autologs() {
    while true; do
		clear
		logs
		sleep 5
    done
}



revcomp() { echo "$1" | tr 'ATCGatcg' 'TAGCtagc' | rev; }
comp() { echo "$1" | tr 'ATCGatcg' 'TAGCtagc';}

#machine-specific aliases

case "$(hostname)" in
    rose)
	alias ilovelinuxwifidrivers="sudo systemctl restart NetworkManager"
	export PATH="/home/mcnoon/miniconda3/bin:$PATH"
    ;;
    *mccleary*)
	umask 002

    #echo "On Yale cluster."
    ;;
    *bouchet*)
	umask 002
    ;;
   maryam*)
	export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
	    export BASH_SILENCE_DEPRECATION_WARNING=1
        export EDITOR="cot"
	    export VISUAL="cot"
	    export CONDA_AUTO_ACTIVATE_BASE=false
	    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
	    export PATH="/opt/homebrew/bin:$PATH"
        ;;
    scriptorium)
	export PATH="/home/mcnoon/miniconda3/bin:$PATH"
	# >>> conda initialize >>>
	# !! Contents within this block are managed by 'conda init' !!
	__conda_setup="$('/home/mcnoon/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
	    eval "$__conda_setup"
	else
	    if [ -f "/home/mcnoon/miniconda3/etc/profile.d/conda.sh" ]; then
		. "/home/mcnoon/miniconda3/etc/profile.d/conda.sh"
	    else
		export PATH="/home/mcnoon/miniconda3/bin:$PATH"
	    fi
	fi
	unset __conda_setup
	# <<< conda initialize <<<
	;;
esac


stage() {
    if [ $# -ne 1 ]; then
        echo "Usage: stage <file>"
        return 1
    fi

    local file="$1"
    local dest="10.168.233.165:/home/mcnoon/backup_drives/primus/staging"

    if [ ! -f "$file" ]; then
        echo "Error: '$file' does not exist"
        return 1
    fi

    if [[ "$file" == *.gz ]]; then
        scp "$file" "$dest" && rm -f "$file"
    else
        gzip "$file" || return 1
        scp "${file}.gz" "$dest" && rm -f "${file}.gz"
    fi
}
