git pull > /dev/null 2>&1
cp .bashrc ~
cp .logsort.py ~
cp .jobsum.py ~

mkdir -p ~/.emacs.d/
cp init.el ~/.emacs.d/init.el

cp .octaverc ~/.octaverc
