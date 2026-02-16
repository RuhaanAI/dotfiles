;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
;; Ruhaan's Doom Emacs config — Org + Org-roam(+UI) working
;; ----------------------------------------------------------------------------
;; Place this in ~/.config/doom/config.el
;; Run:  ~/.emacs.d/bin/doom clean && ~/.emacs.d/bin/doom sync -u && ~/.emacs.d/bin/doom build
;; ----------------------------------------------------------------------------

;; ──────────────────────────────── Identity & visuals ────────────────────────────────
(setq user-full-name "Ruhaan Mukherjee"
      user-mail-address "ruhaanmukherjee@gmail.com")

(setq doom-theme 'doom-gruvbox)
(setq display-line-numbers-type 'relative)

;; ──────────────────────────────── Customize isolation ────────────────────────────────
;; Prevent malformed custom.el from breaking startup
(setq custom-file (expand-file-name "custom-vars.el" doom-user-dir))
;; We intentionally DO NOT load it at startup. Doom will attempt to load
;; `custom-file` once during boot; pointing it at a non-existent file is safe.
;; Emacs will write Customize changes here later.
(when (file-exists-p custom-file)
  (ignore-errors (load custom-file 'noerror 'nomessage)))

;; ──────────────────────────────── Core paths ─────────────────────────────────────────
(setq org-directory (expand-file-name "/Users/ruhaanmukherjee/Library/Mobile Documents/com~apple~CloudDocs/org"))
(defvar rm/notes-root       (expand-file-name "notes" org-directory))
(defvar rm/collections-root (expand-file-name "collections" rm/notes-root))
(defvar rm/quicknotes-dir   (expand-file-name "quicknotes" rm/notes-root))
(defvar rm/quicknotes-file  (expand-file-name "quicknotes.org" rm/quicknotes-dir))

(setq org-roam-directory (file-truename rm/collections-root))
(setq org-roam-db-location (expand-file-name "org-roam.db" (file-truename rm/collections-root)))
(setq org-roam-file-extensions '("org"))

(setq org-id-link-to-org-use-id t)
(add-hook 'org-mode-hook
          (lambda ()
            (when (and (buffer-file-name)i
                       (string-match-p "\\.org\\'" (buffer-file-name)))
              (org-id-get-create))))

;; ──────────────────────────────── ORG setup ──────────────────────────────────────────
(after! org
  (dolist (dir (list rm/notes-root rm/collections-root rm/quicknotes-dir
                     (expand-file-name "journal" org-directory)))
    (unless (file-directory-p dir) (make-directory dir t)))
  (unless (file-exists-p rm/quicknotes-file)
    (with-temp-file rm/quicknotes-file (insert "#+title: Quicknotes\n\n")))

  (setq org-agenda-files
        (list (expand-file-name "inbox.org"    org-directory)
              (expand-file-name "tasks.org"    org-directory)
              (expand-file-name "projects.org" org-directory)
              (expand-file-name "someday.org"  org-directory)
              (expand-file-name "calendar.org" org-directory)
              (expand-file-name "journal/"     org-directory)))

  (setq org-todo-keywords '((sequence "TODO(t)" "WAIT(w@/!)" "HOLD(h@)" "|" "DONE(d!)" "CANX(c@!)")))

  (defun rm/slugify (s) (downcase (replace-regexp-in-string "[^a-z0-9_-]" "-" (string-trim s))))
  (defun rm/capitalize-words (s) (mapconcat #'capitalize (split-string s "[-_ ]+") " "))

  (defun rm/collections-pick-file ()
    (let* ((col-dirs (seq-filter (lambda (d) (and (file-directory-p d)
                                                  (not (string-prefix-p "." (file-name-nondirectory d)))))
                                 (directory-files rm/collections-root t)))
           (col-names (mapcar #'file-name-nondirectory col-dirs))
           (collection (completing-read "Collection folder: " (append col-names '("➕ New…")) nil t))
           (collection (if (string= collection "➕ New…")
                           (let* ((raw (read-string "New collection name: "))
                                  (safe (rm/slugify raw))
                                  (dir (expand-file-name safe rm/collections-root)))
                             (unless (file-directory-p dir) (make-directory dir t)) safe)
                         collection))
           (folder (expand-file-name collection rm/collections-root))
           (files (seq-filter (lambda (f) (and (file-regular-p f) (string-match-p "\\.org\\'" f)))
                              (directory-files folder t)))
           (choices (mapcar #'file-name-nondirectory files))
           (choice (completing-read "File (choose or create): " (append choices '("➕ New file…")) nil t)))
      (cond ((string= choice "➕ New file…")
             (let* ((raw (read-string "New file name (e.g., chap2): "))
                    (safe (rm/slugify raw))
                    (abs (expand-file-name (concat safe ".org") folder)))
               (unless (file-exists-p abs)
                 (with-temp-file abs (insert (format "#+title: %s\n\n" (rm/capitalize-words safe)))))
               abs))
            (t (expand-file-name choice folder)))))

  (defun rm/capture--goto-collection ()
    (find-file (rm/collections-pick-file)) (goto-char (point-max)))

  (setq org-capture-templates
        `(("t" "Task (inbox)" entry (file ,(expand-file-name "inbox.org" org-directory))
           "* TODO %?\nCREATED: %U\n" :prepend t)
          ("c" "Calendar" entry (file ,(expand-file-name "calendar.org" org-directory))
           "* %?  :calendar:\nSCHEDULED: %^t\n" :prepend t)
          ("p" "Project" entry (file ,(expand-file-name "projects.org" org-directory))
           "* %^{Project title}\n:PROPERTIES:\n:AREA: %^{Area|School|Work|Personal}\n:END:\n** TODO Define next action\n%?\n" :prepend t)
          ("n" "Notes")
          ("nq" "Quick note" entry (file ,rm/quicknotes-file)
           "* %^{Heading}\n%U\n%?\n" :prepend t)
          ("nc" "Collection note" entry (function rm/capture--goto-collection)
           "* %^{Heading}\n%U\n%?\n" :prepend t)
          ("j" "Journal" entry (file+olp+datetree ,(expand-file-name "journal/journal.org" org-directory))
           "* %U\n%?\n")))

  (setq org-refile-targets '(((,(expand-file-name "tasks.org" org-directory)
                               ,(expand-file-name "projects.org" org-directory)
                               ,(expand-file-name "someday.org" org-directory)) :maxlevel . 3)))
  (setq org-outline-path-complete-in-steps nil
        org-refile-use-outline-path t
        org-deadline-warning-days 7
        org-agenda-span 'week
        org-agenda-start-on-weekday 1
        org-agenda-skip-deadline-prewarning-if-scheduled t)

  (add-to-list 'org-modules 'org-habit)
  (setq org-habit-graph-column 60
        org-hide-leading-stars t
        org-startup-indented t))

;; ──────────────────────────────── Org-roam & UI ──────────────────────────────────────
(after! org-roam
  (org-roam-db-autosync-mode 1)
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag))))

(use-package! org-roam-ui
  :after org-roam
  :hook (org-roam-mode . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))
;; ───────────────────────────────────── vterm support ───────────────────────────────────
(use-package! vterm
  :commands vterm vterm-other-window
  :config
  (setq vterm-shell "/bin/zsh"))

;; ───────────────────────────────────── Tabs (built-in) ─────────────────────────────────
;; Lightweight, native Emacs tabs using tab-bar-mode (Emacs 27+)
(setq tab-bar-show 1                       ;; always show the tab bar when >1 tab
      tab-bar-close-button-show nil        ;; hide the [X]
      tab-bar-new-tab-choice "*scratch*"   ;; buffer to show in new tabs
      tab-bar-new-button-show t
      tab-bar-format '(tab-bar-format-history
                        tab-bar-format-tabs
                        tab-bar-separator
                        tab-bar-format-add-tab))

(tab-bar-mode 1)

;; Handy keybinds: SPC t ...
(map! :leader
      (:prefix ("t" . "tabs")
       :desc "New tab"      "n" #'tab-new
       :desc "Close tab"    "c" #'tab-close
       :desc "Next tab"     "l" #'tab-next
       :desc "Prev tab"     "h" #'tab-previous
       :desc "Rename tab"   "r" #'tab-rename
       :desc "Switch tab" "s" #'tab-switch))
