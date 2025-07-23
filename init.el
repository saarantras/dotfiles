;; Set directory for backup files (filename~)
(setq backup-directory-alist
      `(("." . "~/.emacs.d/backups")))  ;; Change to your preferred location

;; Set directory for auto-save files (#filename#)
(setq auto-save-file-name-transforms
      `((".*" "~/.emacs.d/auto-saves/" t)))

;; Create the directories if they don't exist
(make-directory "~/.emacs.d/backups" t)
(make-directory "~/.emacs.d/auto-saves" t)
