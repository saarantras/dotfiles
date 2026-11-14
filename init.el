;; Set directory for backup files (filename~)
(setq backup-directory-alist
      `(("." . "~/.emacs.d/backups")))  ;; Change to your preferred location

;; Set directory for auto-save files (#filename#)
(setq auto-save-file-name-transforms
      `((".*" "~/.emacs.d/auto-saves/" t)))

;; Create the directories if they don't exist
(make-directory "~/.emacs.d/backups" t)
(make-directory "~/.emacs.d/auto-saves" t)

;; prose-mode: soft-wrap text at a readable width. The file keeps one line
;; per paragraph; window margins narrow the text area to prose-width columns
;; and center it. Toggle with M-x prose-mode.
(defvar prose-width 80
  "Width in columns of the text area in prose-mode.")

(defun prose--update-margins ()
  "Center a prose-width text area in the selected window."
  (let* ((win (selected-window))
         (cur (window-margins win))
         (avail (+ (window-body-width win) (or (car cur) 0) (or (cdr cur) 0)))
         (margin (max 0 (/ (- avail prose-width) 2))))
    (set-window-margins win margin margin)))

(define-minor-mode prose-mode
  "Soft-wrap lines at prose-width columns, centered in the window."
  :lighter " Prose"
  (if prose-mode
      (progn
        (visual-line-mode 1)
        (setq-local fill-column prose-width)
        ;; Buffer-local: runs once per window showing this buffer, with that
        ;; window selected, including after splits and resizes.
        (add-hook 'window-configuration-change-hook #'prose--update-margins nil t)
        (dolist (win (get-buffer-window-list nil nil t))
          (with-selected-window win (prose--update-margins))))
    (visual-line-mode -1)
    (kill-local-variable 'fill-column)
    (remove-hook 'window-configuration-change-hook #'prose--update-margins t)
    (dolist (win (get-buffer-window-list nil nil t))
      (set-window-margins win nil nil))))

;; text-mode covers .txt, .md (markdown-mode derives from it), and similar.
(add-hook 'text-mode-hook #'prose-mode)

;; Stock Emacs has no markdown-mode, so .md would open in fundamental-mode and
;; skip text-mode-hook. Fall back to text-mode when markdown-mode is absent.
(unless (fboundp 'markdown-mode)
  (add-to-list 'auto-mode-alist '("\\.md\\'" . text-mode)))
