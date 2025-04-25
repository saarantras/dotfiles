# .bashrc

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
alias move_contents='function _move() { local dir=$1; for f in $(ls -A | grep -v $dir); do mv "$f" "$dir"; done; }; _move'
alias howbig='du -sh {.,}* | sort -hr'
alias makeref='openssl rand -base64 32'
alias tab="cd ~/project/tabula_rasa"
alias tabdat="cd /gpfs/gibbs/pi/reilly/tabula_data"


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


function logsort() {
grep -rh "^\[[^]]\]" "${1:-.}" . | python3 ~/.logsort.py
}

function autologgrep() {
    if [[ -z "$1" ]]; then
	echo "Usage: autologgrep <dirname>"
        return 1
    fi

    
    while true; do
		clear
		loggrep $1
		sleep 5
    done
}
