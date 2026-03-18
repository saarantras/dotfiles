git pull > /dev/null 2>&1
cp .bashrc ~
cp .logsort.py ~
cp .jobsum.py ~
cp .slurm_run_stats.py ~
cp .gitconfig ~

mkdir -p ~/.local/bin
if [ -f scripts/notify-job.sh ]; then
    cp scripts/notify-job.sh ~/.local/bin/notify-job
    chmod 755 ~/.local/bin/notify-job
fi

mkdir -p ~/.emacs.d/
cp init.el ~/.emacs.d/init.el

cp .octaverc ~/.octaverc
cp .tmux.conf ~/.tmux.conf

mkdir -p ~/.codex/skills
if command -v rsync >/dev/null 2>&1 && [ -d codex/skills ]; then
    rsync -a --delete \
        --exclude '.system/' \
        --exclude '.gitkeep' \
        codex/skills/ ~/.codex/skills/
fi
