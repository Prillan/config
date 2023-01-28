(setq custom-file (expand-file-name "~/longtemp/custom.el"))
(load custom-file)

(eval-and-compile
  (when (getenv "DEBUG") (setq init-file-debug t))
  (setq debug-on-error (and (not noninteractive) init-file-debug)))

(eval-and-compile
  (defvar data-dir
    (if (getenv "XDG_DATA_HOME")
        (concat (getenv "XDG_DATA_HOME") "/emacs/")
      (expand-file-name "~/.local/share/emacs/"))
    "Directory for data.")

  (defvar cache-dir
    (if (getenv "XDG_CACHE_HOME")
        (concat (getenv "XDG_CACHE_HOME") "/emacs/")
      (expand-file-name "~/.cache/emacs/"))
    "Directory for cache.")

  (defvar pictures-dir
    (or (getenv "XDG_PICTURES_DIR")
        (expand-file-name "~/Pictures/"))
    "Directory for pictures."))

(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq ring-bell-function #'ignore
      visible-bell nil)

(setq shell-file-name "bash")

(eval-when-compile
  (require 'use-package nil t))
(setq use-package-always-defer t)

(if init-file-debug
    (setq use-package-verbose t
          use-package-expand-minimally nil
          use-package-compute-statistics t)
  (setq use-package-verbose nil
        use-package-expand-minimally t))

(global-unset-key (kbd "M-c"))
(defvar string-inflection-prefix "M-c"
  "Key prefix for commands related to string inflection.")

(use-package no-littering
  :demand t
  :custom
  (no-littering-etc-directory data-dir)
  (no-littering-var-directory cache-dir))

(use-package general
  :demand t
  :commands (general-define-key))

(use-package piper
    :load-path (-piper-load-path)
    :bind ("C-c C-|" . piper))

(use-package direnv
  :config
  (direnv-mode))

(use-package koka-mode
  :load-path (-koka-load-path)
  :mode "\\.kk\\'")

(require 'po)
(require 'po-mode)

(require 'restclient)

(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-opera t)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(defun screenshot (type)
  "Save a screenshot of the current frame as an image in TYPE format.
Saves to a temp file and puts the filename in the kill ring."
  (let* ((ext (concat "." (symbol-name type)))
         (filename (make-temp-file "Emacs-" nil ext))
         (data (x-export-frames nil type)))
    (with-temp-file filename
      (insert data))
    (kill-new filename)
    (message filename)))

(defun screenshot-svg ()
  "Save a screenshot of the current frame as an SVG image.
Saves to a temp file and puts the filename in the kill ring."
  (interactive)
  (screenshot 'svg))

(defun screenshot-png ()
  "Save a screenshot of the current frame as an PNG image.
Saves to a temp file and puts the filename in the kill ring."
  (interactive)
  (screenshot 'png))

(use-package string-inflection
  :general
  (:prefix
   string-inflection-prefix
   "k" 'string-inflection-kebab-case
   "C" 'string-inflection-camelcase
   "l" 'string-inflection-lower-camelcase
   "s" 'string-inflection-underscore))

(use-package ispell
  :custom
  (ispell-program-name "hunspell"))

(use-package flyspell
  :hook
  ((org-mode
    text-mode) . flyspell-mode))

(use-package whitespace
  :custom
  (whitespace-line-column fill-column)
  (whitespace-style
   '(face
     trailing
     tabs
     lines-tail
     newline
     empty
     space-after-tab
     space-before-tab
     tab-mark
     newline-mark)))

(use-package yasnippet
  :defer 1
  :commands
  (yas--templates-for-key-at-point)
  :custom
  (yas-also-auto-indent-first-line t)
  (yas-snippet-dirs (list (expand-file-name "snippets" user-emacs-directory)))
  ;; Nested snippets
  (yas-triggers-in-field t)
  (yas-wrap-around-region t)
  :general
  (:keymaps
   'yas-minor-mode-map
   [tab] 'nil
   "TAB" 'nil
   "M-o" 'yas-insert-snippet)
  :init
  (setq yas-verbosity 0)
  :config
  (yas-global-mode 1))


;; Using this causes insane loading times in locate-dominating-file
;;
;; (use-package yasnippet-snippets
;;   :hook
;;   (yas-minor-mode . yasnippet-snippets-initialize))

(setq create-lockfiles nil
      make-backup-files nil)

(setq confirm-nonexistent-file-or-buffer t)

(use-package projectile
  :defer 2
  :custom
  (projectile-completion-system 'helm)
  (projectile-globally-ignored-directories
   '(".idea"
     ".ensime_cache"
     ".eunit"
     ".git"
     ".hg"
     ".fslckout"
     "_FOSSIL_"
     ".bzr"
     "_darcs"
     ".tox"
     ".svn"
     ".stack-work"
     ".venv"))
  (projectile-keymap-prefix "p")
  (projectile-switch-project-action 'projectile-find-file)
  (projectile-globally-ignored-file-suffixes
   '(".elc" ".pyc" ".o" ".hi" ".class" ".cache"))
  :config
  (setq projectile-globally-ignored-directories
        (append '("_build"
                  "target" "project/target"
                  "vendor/bundle" "vendor/cache"
                  "elm-stuff" "tests/elm-stuff")
                projectile-globally-ignored-directories))
  (setq projectile-other-file-alist
        (append '(("less" "css")
                  ("styl" "css")
                  ("sass" "css")
                  ("scss" "css")
                  ("css" "scss" "sass" "less" "styl")
                  ("jade" "html")
                  ("pug" "html")
                  ("html" "jade" "pug" "jsx" "tsx"))
                projectile-other-file-alist))
  (setq projectile-project-root-files
        (append '("package.json" "Package.swift" "README.md")
                projectile-project-root-files))

  (projectile-mode 1))

(use-package dockerfile-mode)

(use-package jq-mode
  :mode "\\.jq\\'")

(require 'lsp)
(require 'lsp-haskell)

(use-package lsp-mode
  :hook
  (scala-mode . lsp)
  (haskell-mode . lsp)
  (lsp-mode . lsp-lens-mode)
  :config
  (setq lsp-prefer-flymake nil)
  (setq lsp-keymap-prefix "§")
  (define-key lsp-mode-map (kbd "§") lsp-command-map))

(use-package hledger-mode
  :mode ("\\.journal\\'" "\\.hledger\\'"))

(setq gc-cons-threshold (* 8 1024 1024))
(setq read-process-output-max (* 1024 1024))
;; https://emacs-lsp.github.io/lsp-mode/page/performance/

(use-package nix-mode
  :mode ("\\.nix\\'" "\\.nix.in\\'"))
(use-package nix-drv-mode
  :ensure nix-mode
  :mode "\\.drv\\'")
(use-package nix-shell
  :ensure nix-mode
  :commands (nix-shell-unpack nix-shell-configure nix-shell-build))
(use-package nix-repl
  :ensure nix-mode
  :commands (nix-repl))

(use-package magit
  :defer 2
  ;; :hook
  ;; (git-commit-mode . +git-commit-set-fill-column)
  :custom
  (magit-log-buffer-file-locked t)
  (magit-refs-show-commit-count 'all)
  (magit-save-repository-buffers 'dontask)
  (vc-msg-git-show-commit-function 'magit-show-commit)
  :general
  ("C-c g d" 'magit-diff-unstaged)
  ("C-c g p" 'magit-push)
  ("C-c g f f" 'magit-find-file)
  ("C-c g b" 'magit-blame)
  ("C-c g c" 'magit-commit)
  ("C-c g l" 'magit-log-current)
  ("C-c g h" 'magit-log-buffer-file)
  ("C-c g s" 'magit-status)
  (:keymaps
   'dired-mode-map
   "C-x g" 'magit)
  :config
  ;; Unset pager as it is not supported properly inside emacs.
  (setenv "GIT_PAGER" ""))

(use-package magit-todos-mode
  :defer 2)

(use-package dumb-jump
  :general
  (:keymaps
   'dumb-jump-mode-map
   "C-c d o" 'dumb-jump-go-other-window
   "C-c d d" 'dumb-jump-go
   "C-c d i" 'dumb-jump-go-prompt
   "C-c d x" 'dumb-jump-go-prefer-external
   "C-c d z" 'dumb-jump-go-prefer-external-other-window))

(use-package python
  :hook
  (python-mode . lsp))

(use-package haskell-mode)

;; SCALA

;; Enable sbt mode for executing sbt commands
(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
   ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
   (setq sbt:program-options '("-Dsbt.supershell=false"))
   )

;; JAVA

(use-package lsp-java
  :config (add-hook 'java-mode-hook 'lsp))


(use-package flycheck
  :init (global-flycheck-mode))

(helm-mode)

;; Edit server
(use-package edit-server
  :ensure t
  :commands edit-server-start
  :init (if after-init-time
            (edit-server-start)
          (add-hook 'after-init-hook
                    #'(lambda() (edit-server-start))))
  :config (setq edit-server-new-frame-alist
                '((name . "Edit with Emacs FRAME")
                  (top . 200)
                  (left . 200)
                  (width . 80)
                  (height . 25)
                  (minibuffer . t)
                  (menu-bar-lines . t)
                  (window-system . x))))

;; COMMON FUNCTIONS

(defun hash-uuidgen ()
  (interactive)
  (shell-command "uuidgen | xargs echo -n" (quote (4)) nil))

(defun hash-uuid-split (str)
  (interactive)
  (concat (substring str 0 8)
          "-"
          (substring str 8 12)
          "-"
          (substring str 12 16)
          "-"
          (substring str 16 20)
          "-"
          (substring str 20 32)))

;;; Stefan Monnier <foo at acm.org>. It is the opposite of
;;; fill-paragraph
(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
        ;; This would override `fill-column' if it's an integer.
        (emacs-lisp-docstring-fill-column t))
    (fill-paragraph nil region)))

(defun hash-kill-forward-whitespace ()
  (interactive)
  (set-mark-command 'nil)
  (search-forward-regexp "[^ \\t]")
  (backward-char 1)
  (kill-region (point) (mark)))

(defun hash-remove-whitespace-at-line-end ()
  (interactive)
  (replace-regexp "[ ]+$" "" nil
		  (if (and transient-mark-mode mark-active)
		      (region-beginning))
		  (if (and transient-mark-mode mark-active)
		      (region-end))))

;; LaTeX greek/dollar stuff
(defun hash-insert-dollar ()
  "Inserts two dollar signs with TeX-insert-dollar and moves in the point between them"
  (interactive)
  (TeX-insert-dollar)
  (TeX-insert-dollar)
  (backward-char))

(setq hash-greek-char-map '(
			   ("alpha" 97)
			   ("beta" 98)
			   ("gamma" 99)
			   ("Gamma" 67)
			   ("delta" 100)
			   ("Delta" 68)
			   ("epsilon" 101)
			   ("zeta" 102)
			   ("eta" 103)
			   ("theta" 104)
			   ("varTheta" 72)
			   ("iota" 105)
			   ("kappa" 106)
			   ("lambda" 107)
			   ("Lambda" 75)
			   ("mu" 108)
			   ("nu" 109)
			   ("xi" 110)
			   ("Xi" 78)
			   ("omicron" 111)
			   ("pi" 112)
			   ("Pi" 80)
			   ("rho" 113)
			   ("sigma_final" 114)
			   ("sigma" 115)
			   ("Sigma" 83)
			   ("tau" 116)
			   ("upsilon" 117)
			   ("phi" 118)
			   ("Phi" 86)
			   ("chi" 119)
			   ("psi" 120)
			   ("varpsi" 120)
			   ("Psi" 88)
			   ("omega" 121)
			   ("Omega" 89)))

(setq hash-symbol-char-map '(
			      ("forall" #x22)
			      ("exists" #x24)
			      ("leq" #xA3)
			      ("geq" #xB3)
			      ("infty" #xA5)
			      ("leftrightarrow" #xAB)
			      ("leftarrow" #xAC)
			      ("uparrow" #xAD)
			      ("map" #xAE)
			      ("rightarrow" #xAE)
			      ("downarrow" #xAF)
			      ("times" #xB4)
			      ("partial" #xB6)
			      ("cdot" #xB7)
			      ("neq" #xB9)
			      ("equiv" #xBA)
			      ("dots" #xBC)
			      ("varnothing" #xC6)
			      ("cap" #xC7)
			      ("cup" #xC8)
			      ("subset" #xCC)
			      ("subseteq" #xCD)
			      ("in" #xCE)
			      ("nin" #xCF)
			      ("nabla" #xD1)
			      ("prod" #xD5)
			      ("sum" #xE5)
			      ("sqrt" #xD6)
			      ("neg" #xD8)
			      ("wedge" #xD9)
			      ("vee" #xDA)
			      ("Leftrightarrow" #xDB)
			      ("Leftarrow" #xDC)
			      ("Uparrow" #xDD)
			      ("Rightarrow" #xDE)
			      ("Downarrow" #xDF)
			      ("int" #xF2)))

(setq hash-unicode-char-map '(
			      ("mapsto" ?\u21A6)
			      ("Longleftrightarrow" ?\u27FA)
			      ("Longleftarrow" ?\u27F8)
			      ("Longrightarrow" ?\u27F9)
			      ("longleftrightarrow" ?\u27F7)
			      ("longleftarrow" ?\u27F5)
			      ("longrightarrow" ?\u27F6)
			      ("N" ?\u2115)
			      ("R" ?\u211D)
			      ("Z" ?\u2124)
			      ("Q" ?\u211A)
			      ("C" ?\u2102)
			      ("simeq" ?\u2243)
			      ("models" ?\u22A8)
			      ("nmodels" ?\u22AD)
			      ("proves" ?\u22A2)
			      ("nproves" ?\u22AC)
			      ("langle" ?\u27E8)
			      ("rangle" ?\u27E9)
			      ("circ" ?\u2218)
			      ("oplus" ?\u2295)
			      ("otimes" ?\u2297)))

(defun hash-get-item-from-list (item list test)
  (cond
   ((equal list nil) nil)
   ((funcall test item (car list)) (car list))
   (t (hash-get-item-from-list item (cdr list) test))))

(defun hash-get-greek-map-for-name (name)
  (hash-get-item-from-list
   name
   hash-greek-char-map
   (lambda (x y) (equal x (car y)))))

(defun hash-translate-greek (x)
  (cond
    ((string= x "a") 'LaTeX-math-alpha)
    ((string= x "b") 'LaTeX-math-beta)
    ((string= x "g") 'LaTeX-math-gamma)
    ((string= x "G") 'LaTeX-math-Gamma)
    ((string= x "d") 'LaTeX-math-delta)
    ((string= x "D") 'LaTeX-math-Delta)
    ((string= x "e") 'LaTeX-math-epsilon)
    ((string= x "z") 'LaTeX-math-zeta)
    ((string= x "h") 'LaTeX-math-eta)
    ((string= x "ð") 'LaTeX-math-theta)
    ((string= x "Ð") 'LaTeX-math-varTheta)
    ((string= x "i") 'LaTeX-math-iota)
    ((string= x "k") 'LaTeX-math-kappa)
    ((string= x "l") 'LaTeX-math-lambda)
    ((string= x "L") 'LaTeX-math-Lambda)
    ((string= x "m") 'LaTeX-math-mu)
    ((string= x "n") 'LaTeX-math-nu)
    ((string= x "x") 'LaTeX-math-xi)
    ((string= x "X") 'LaTeX-math-Xi)
    ((string= x "p") 'LaTeX-math-pi)
    ((string= x "P") 'LaTeX-math-Pi)
    ((string= x "r") 'LaTeX-math-rho)
    ((string= x "s") 'LaTeX-math-sigma)
    ((string= x "S") 'LaTeX-math-Sigma)
    ((string= x "t") 'LaTeX-math-tau)
    ((string= x "u") 'LaTeX-math-upsilon)
    ((string= x "f") 'LaTeX-math-varphi)
    ((string= x "F") 'LaTeX-math-Phi)
    ((string= x "c") 'LaTeX-math-chi)
    ((string= x "þ") 'LaTeX-math-psi)
    ((string= x "Þ") 'LaTeX-math-Psi)
    ((string= x "ö") 'LaTeX-math-omega)
    ((string= x "Ö") 'LaTeX-math-Omega)
    (t nil)
    )
  )

(defconst hash-greek-keys "abgGdDezhðÐiklLmnxXpPrsStufFcþÞöÖ")

(defun hash-bind-greek ()
  "Binds characters to respective greek ones"
  (interactive)
  (dolist
      (x (mapcar (lambda (x) (cons x (cons (hash-translate-greek (string x)) nil))) (symbol-value 'hash-greek-keys)))
    (message (string (first x)))
    (message (symbol-name (first (rest x))))
    (local-set-key (string (first x)) (first (rest x))))
  (message "Greek lock ON")
  )

(defun hash-unbind-greek ()
  "Unbinds characters from respective greek ones"
  (interactive)
  (dolist
      (x (mapcar 'string (symbol-value 'hash-greek-keys)))
    (local-unset-key x))
  (message "Greek lock OFF"))

(defun hash-toggle-greek ()
  "Toggles between greek characters and standard current state is in hash-greek-lock"
  (interactive)
  (if (equal (symbol-value 'hash-greek-lock) 1)
      (progn (setq hash-greek-lock nil)
	     (hash-unbind-greek))
    (progn (setq hash-greek-lock 1)
	   (hash-bind-greek))))

(defun hash-insert-greek (c)
  "Inserts a single greek character"
  (interactive "c")
  (funcall (hash-translate-greek (string c)) nil))

;;read-from-minibuffer prompt &optional initial keymap read history default inherit-input-method
(defun hash-read-latex-from-minibuffer (prompt &optional default)
  "Reads latex from the minibuffer"
  (prog2
      (local-set-key (kbd "<RET>") 'exit-minibuffer)
      (read-from-minibuffer prompt default (current-local-map) nil nil default t)
      (local-set-key (kbd "<RET>") 'TeX-newline)
      ))

(defun hash-LaTeX-math-underset ()
  "Inserts underset"
  (interactive)
  (LaTeX-math-underset nil)
  (TeX-insert-braces nil)
  (insert (hash-read-latex-from-minibuffer "Under: "))
  (forward-char)
  (TeX-insert-braces nil)
  (insert (hash-read-latex-from-minibuffer "Over: "))
  (forward-char))

(defun hash-LaTeX-math-overset ()
  "Inserts overset"
  (interactive)
  (LaTeX-math-overset nil)
  (TeX-insert-braces nil)
  (insert (hash-read-latex-from-minibuffer "Over: "))
  (forward-char)
  (TeX-insert-braces nil)
  (insert (hash-read-latex-from-minibuffer "Under: "))
  (forward-char))

(defun hash-LaTeX-math-overbar ()
  "Inserts overbar"
  (interactive)
  (TeX-insert-macro "overbar")
  (TeX-insert-braces nil))

(defun hash-LaTeX-math-set ()
  "Inserts a set"
  (interactive)
  (TeX-insert-macro "set"))
(defun hash-LaTeX-math-setp ()
  "Inserts a set"
  (interactive)
  (TeX-insert-macro "setp"))

(defun hash-LaTeX-math-proves ()
  (interactive)
  (TeX-insert-macro "proves"))

(defun hash-insert-display-math ()
  (interactive)
  (reindent-then-newline-and-indent)
  (insert "\\[")
  (reindent-then-newline-and-indent)
  (reindent-then-newline-and-indent)
  (insert "\\]")
  (previous-line))

(defun pretty-lambdas ()
  (font-lock-add-keywords
   nil `(("\\(\\\\lambda\\>\\)"
	  (0 (progn (compose-region (match-beginning 1) (match-end 1)
				    ,(make-char 'greek-iso8859-7 107))
		    nil))))))

(defun hash-LaTeX-pretty-macro (name char)
  (print (concat "Replacing " name " with:"))
  (print char)
  (font-lock-add-keywords
   nil `((,(concat "\\(\\\\" name "\\>\\)")
	  (0 (progn (compose-region (match-beginning 1) (match-end 1)
				    ,char)
		    nil))))))

;; (defun hash-LaTeX-highlight-todo ()
;;   (font-lock-add-keywords
;;    nil '(("\\(\\\\todo\\)" . 'font-lock-keyword-face))))

(defun hash-LaTeX-pretty-macro-list (list charset)
  (dolist (x list)
    (hash-LaTeX-pretty-macro
     (car x)
     (make-char charset (cadr x)))))
(defun hash-LaTeX-pretty-macro-list-wo-make (list)
  (dolist (x list)
    (hash-LaTeX-pretty-macro
     (car x)
     (cadr x))))

(defun hash-LaTeX-pretty-macros ()
  (hash-LaTeX-pretty-macro-list hash-greek-char-map 'greek-iso8859-7)
  (hash-LaTeX-pretty-macro-list hash-symbol-char-map 'symbol)
  (hash-LaTeX-pretty-macro-list-wo-make hash-unicode-char-map))


(defun hash-insert-sequence ()
  (interactive)
  (let ((element (hash-read-latex-from-minibuffer "Element: " "x"))
	(separator (hash-read-latex-from-minibuffer "Separator: " ","))
	(startidx (hash-read-latex-from-minibuffer "Start index: " "0"))
	(stopidx (hash-read-latex-from-minibuffer "Stop index: " "n")))
    (insert element)
    (insert "_{")
    (insert startidx)
    (insert "}")
    (insert separator)
    (insert " ")
    (TeX-insert-macro "dots")
    (insert " ")
    (insert separator)
    (insert element)
    (insert "_{")
    (insert stopidx)
    (insert "}")))

(defun hash-LaTeX-env-python (env)
  (LaTeX-insert-environment "python")
  (move-beginning-of-line nil)
  (kill-line)
  (newline)
  (previous-line)
  (mmm-parse-buffer))

(defun hash-LaTeX-reformat-compile ()
  (interactive)
  (LaTeX-fill-paragraph)
  (TeX-command-run-all nil))

(defun hash-LaTeX-promote-heading ()
  (interactive)
  (let ((w (thing-at-point 'word)))
    (if
        (not (eq w 'nil))
        (hash-replace-word-at-point
         (-hash-LaTeX-promote-heading (thing-at-point 'word)))
      (message "No word at point"))))

(defun hash-LaTeX-demote-heading ()
  (interactive)
  (let ((w (thing-at-point 'word)))
    (if
        (not (eq w 'nil))
        (hash-replace-word-at-point
         (-hash-LaTeX-demote-heading (thing-at-point 'word)))
      (message "No word at point"))))

(defun hash-replace-word-at-point (new-word)
  (save-match-data
    (let ((bounds (bounds-of-thing-at-point 'word)))
      (set-match-data (list (car bounds) (cdr bounds)))
      (replace-match new-word))))

(defun -hash-LaTeX-promote-heading (w)
  (cond ((equal w "subsubsection") "subsection")
        ((equal w "subsection") "section")
        ((equal w "section") "chapter")
        (t w)))

(defun -hash-LaTeX-demote-heading (w)
  (cond ((equal w "subsection") "subsubsection")
        ((equal w "section") "subsection")
        ((equal w "chapter") "section")
        (t w)))

(defun hash-tex-settings ()

  (setq TeX-parse-self t) ; Enable parse on load.
  (setq TeX-auto-save t) ; Enable parse on save.

  (local-set-key (kbd "C-<") 'TeX-insert-braces)
  (local-set-key (kbd "M-m") 'hash-insert-dollar)
  (local-set-key (kbd "C-M-m") 'hash-insert-display-math)
  (local-set-key (kbd "<M-S-left>") 'hash-LaTeX-promote-heading)
  (local-set-key (kbd "<M-S-right>") 'hash-LaTeX-demote-heading)
  (local-set-key (kbd "C-c <right>") 'LaTeX-math-rightarrow)
  (local-set-key (kbd "C-c <down>") 'LaTeX-math-downarrow)
  (local-set-key (kbd "C-c <left>") 'LaTeX-math-leftarrow)
  (local-set-key (kbd "C-c <up>") 'LaTeX-math-leftrightarrow)
  (local-set-key (kbd "C-c <S-right>") 'LaTeX-math-Rightarrow)
  (local-set-key (kbd "C-c <S-left>") 'LaTeX-math-Leftarrow)
  (local-set-key (kbd "C-c <S-up>") 'LaTeX-math-Leftrightarrow)
  (local-set-key (kbd "C-c l <right>") 'LaTeX-math-longrightarrow)
  (local-set-key (kbd "C-c l <left>") 'LaTeX-math-longleftarrow)
  (local-set-key (kbd "C-c l <up>") 'LaTeX-math-longleftrightarrow)
  (local-set-key (kbd "C-c l <S-right>") 'LaTeX-math-Longrightarrow)
  (local-set-key (kbd "C-c l <S-left>") 'LaTeX-math-Longleftarrow)
  (local-set-key (kbd "C-c l <S-up>") 'LaTeX-math-Longleftrightarrow)
  (local-set-key (kbd "C-c p") 'hash-LaTeX-math-proves)
  (local-set-key (kbd "C-c s") 'hash-LaTeX-math-set)
  (local-set-key (kbd "C-c m") 'LaTeX-math-models)
  (local-set-key (kbd "C-c n") 'LaTeX-math-neg)
  (local-set-key (kbd "C-c i") 'LaTeX-math-in)
  (local-set-key (kbd "C-c &") 'LaTeX-math-wedge)
  (local-set-key (kbd "C-c |") 'LaTeX-math-vee)

  (local-set-key (kbd "C-c /") 'LaTeX-math-frac)

  (local-set-key (kbd "C-c 0") 'LaTeX-math-varnothing)
  (local-set-key (kbd "C-c +") 'LaTeX-math-oplus)
  (local-set-key (kbd "C-c *") 'LaTeX-math-cdot)

  (local-set-key (kbd "C-c (") 'LaTeX-math-langle)
  (local-set-key (kbd "C-c )") 'LaTeX-math-rangle)

  (local-set-key (kbd "C-c =") 'LaTeX-math-simeq)

  (local-set-key (kbd "C-c o +") 'LaTeX-math-oplus)
  (local-set-key (kbd "C-c o *") 'LaTeX-math-otimes)

  ;; Complex commands
  (local-set-key (kbd "C-c c u") 'hash-LaTeX-math-underset)
  (local-set-key (kbd "C-c c o") 'hash-LaTeX-math-overset)
  (local-set-key (kbd "C-c c &") 'LaTeX-math-cap)
  (local-set-key (kbd "C-c c |") 'LaTeX-math-cup)
  (local-set-key (kbd "C-c c *") 'LaTeX-math-times)
  (local-set-key (kbd "C-c c -") 'LaTeX-math-setminus)
  (local-set-key (kbd "C-c c s") 'hash-LaTeX-math-setp)

  (local-set-key (kbd "C-c <") 'LaTeX-math-leq)
  (local-set-key (kbd "C-c >") 'LaTeX-math-geq)
  (local-set-key (kbd "C-c c <") 'LaTeX-math-subset)
  (local-set-key (kbd "C-c c >") 'LaTeX-math-supset)
  (local-set-key (kbd "C-c c C-s <") 'LaTeX-math-sqsubseteq)

  (local-set-key (kbd "C-c c _") 'hash-LaTeX-math-overbar)

  (local-set-key (kbd "C-c c .") 'hash-insert-sequence)

  (local-set-key (kbd "½") 'hash-toggle-greek)
  (local-set-key (kbd "§") 'hash-insert-greek)

  (local-set-key (kbd "<f2>") 'hash-LaTeX-reformat-compile)

  (hash-LaTeX-pretty-macros)
  ;;(hash-LaTeX-pretty-macro "mapsto" ?↦)

  (setq hash-greek-lock nil)
  (make-local-variable 'hash-greek-lock)

  (TeX-add-style-hook
   "python"
   (lambda ()
     (LaTeX-add-environments
      '("python" hash-LaTeX-env-python))))
  (reftex-mode))

(add-hook 'TeX-mode-hook 'hash-tex-settings)

(defun hash-align-haskell-record (start end)
  "Aligns current region using ::"
  (interactive "r") ;; r → (start end)
  (align-regexp start end "\\(\\s-*\\)::"))

(defun hash-align-pipes (start end)
  "Aligns current region using |"
  (interactive "r") ;; r → (start end)
  (align-regexp start end "\\(\\s-*\\)|" 1 1 t))

(defun hash-md-2-org (start end)
  (interactive "r")
  (replace-string "--|--" "--+--" nil start end))

(defun hash-org-2-md (start end)
  (interactive "r")
  (replace-string "--+--" "--|--" nil start end))

(defun hash-markdown-settings ()
  (local-set-key (kbd "C-c t m") 'hash-org-2-md)
  (local-set-key (kbd "C-c t o") 'hash-md-2-org)
  (local-unset-key (kbd "C-c C-f"))
  (local-set-key (kbd "C-c C-f C-b") 'markdown-insert-bold)
  (local-set-key (kbd "C-c C-f C-e") 'markdown-insert-italic))
(add-hook 'markdown-mode-hook 'hash-markdown-settings)

(defun convert-date-to-iso (start stop)
  (interactive "r")
  (shell-command-on-region
   start
   stop
   "xargs -I{} date -Iseconds --date '{}' | tr -d '\n'"
   t
   t
   nil
   t
   nil))

(defun replace-last-sexp ()
  (interactive)
  (let ((value (eval (preceding-sexp))))
    (kill-sexp -1)
    (insert (format "%S" value))))

(defun hash-shell-on-region (point mark)
  (interactive "r")
  (shell-command-on-region
   point
   mark
   (read-shell-command "Run through shell command: ")
   :REPLACE t))

;; (MA)GIT

;; Global bindings
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "M-Q") 'unfill-paragraph)

(global-set-key (kbd "C-c 3") 'comment-region)
(global-set-key (kbd "C-c #") 'uncomment-region)
(global-set-key (kbd "C-c r") 'replace-string)
;; (global-set-key (kbd "C-c a r") 'hash-align-haskell-record)
;; (global-set-key (kbd "C-c a p") 'hash-align-pipes)
(global-set-key (kbd "C-c f j") 'json-pretty-print)
(global-set-key (kbd "C-x B")  'mode-line-other-buffer)
(global-set-key (kbd "C-c C-e") 'replace-last-sexp)
(global-set-key (kbd "C-ö") 'mc/mark-next-like-this)
(global-set-key (kbd "C-Ö") 'mc/mark-all-like-this)
(global-set-key (kbd "C-ä") 'mc/mark-next-lines)
(global-set-key (kbd "C-c s") 'hash-shell-on-region)

(defun hash-hyper-checkmark ()
  (interactive)
  (insert-char 10003 1 t))

(defun hash-hyper-crossmark ()
  (interactive)
  (insert-char 10060 1 t))

(defun hash-hyper-rightarrow ()
  (interactive)
  (insert-char 8594 1 t))


(global-set-key (kbd "C-c h +") 'hash-hyper-checkmark)
(global-set-key (kbd "C-c h -") 'hash-hyper-crossmark)
(global-set-key (kbd "C-c h <right>") 'hash-hyper-rightarrow)

(global-unset-key (kbd "C-z"))
(multiple-cursors-mode)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:background nil))))
 '(org-level-1 ((t (:inherit outline-1 :height 1.3))))
 '(org-level-2 ((t (:inherit outline-2))))
 '(org-level-3 ((t (:inherit outline-3)))))
