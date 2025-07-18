# .bashrc

# auto-update dotfiles from my git repo
cd ~/dotfiles
bash update.sh >/dev/null
cd - > /dev/null

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
alias emacs="emacs -nw"
alias move_contents='function _move() { local dir=$1; for f in $(ls -A | grep -v $dir); do mv "$f" "$dir"; done; }; _move'
alias howbig='du -sh {.,}* | sort -hr'
alias makeref='openssl rand -base64 32'
alias tab="cd ~/project/tabula_rasa"
alias tabdat="cd /gpfs/gibbs/pi/reilly/tabula_data"
alias bcluster="ssh mcn26@bouchet.ycrc.yale.edu"
alias cluster="ssh mcn26@login2.mccleary.ycrc.yale.edu"

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
    *mccleary*)
        #echo "On Yale cluster."
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
	
	;;
esac


