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
if [ -f scripts/prio-cost.sh ]; then
    cp scripts/prio-cost.sh ~/.local/bin/prio-cost
    chmod 755 ~/.local/bin/prio-cost
fi

mkdir -p ~/.emacs.d/
cp init.el ~/.emacs.d/init.el

cp .octaverc ~/.octaverc
cp .tmux.conf ~/.tmux.conf

cp AIGUIDE.md ~/.claude/CLAUDE.md
cp AIGUIDE.md ~/.codex/AGENTS.md

mkdir -p ~/.codex/skills ~/.claude/skills
if command -v rsync >/dev/null 2>&1 && [ -d skills ]; then
    rsync -a --delete \
        --exclude '.system/' \
        --exclude '.gitkeep' \
        skills/ ~/.codex/skills/
    rsync -a --delete \
        --exclude '.system/' \
        --exclude '.gitkeep' \
        skills/ ~/.claude/skills/
fi
