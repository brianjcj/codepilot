

(setq mydir "")
(setq mydir
      (file-name-directory
       (or load-file-name (buffer-file-name))))


(add-to-list 'load-path (directory-file-name mydir))
(add-to-list 'load-path (concat mydir "import"))
(add-to-list 'load-path (concat mydir "misc"))


(setq case-fold-search t)
(setq display-time-mode t)
(setq ido-enable-flex-matching t)
(setq scroll-conservatively 10)
(setq scroll-step 1)


(setq column-number-mode t)
(setq mouse-yank-at-point t)
(show-paren-mode t)
(setq show-paren-style 'parentheses)
;;(mouse-avoidance-mode 'animate)
(setq frame-title-format "%b[%f]@emacs")
(setq default-major-mode 'text-mode)
(setq next-line-add-newlines nil)
(setq make-backup-files nil) ;; Don't create the backup file
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
(setq-default indent-tabs-mode nil)
(setq set-mark-command-repeat-pop t)
;; (setq mouse-drag-copy-region nil)
(setq inhibit-startup-screen t)


(which-function-mode t)

;; ====================
;; undo and redo
;; ====================
(require 'redo)
(global-set-key [(f5)] 'undo)
(global-set-key [(shift f5)] 'redo)


;; ================================
;;  % for paren match
;; ================================
(global-set-key "%" 'match-paren)

(defun match-paren (arg)
  "Go to the matching paren if on a paren; otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))


;; ibuffer
(require 'ibuffer)
(global-set-key (kbd "C-x C-b") 'ibuffer)


;; linum, much faster than setnu!!! Use it.
(require 'linum)
(setq linum-eager nil)


;; browse-kill-ring
(require 'browse-kill-ring)
;; (global-set-key [(control c)(k)] 'browse-kill-ring)
(browse-kill-ring-default-keybindings)


(require 'ido)
(ido-mode t)


(cua-mode t)


(auto-image-file-mode t)


(setq-default save-place t)
(require 'saveplace)
(require 'savehist)
(require 'recentf)

(recentf-mode t)
(savehist-mode t)


(require 'test)


(defun vi-list ()
  "Simulate a :set list in Vi."
  (interactive)
  (standard-display-ascii ?\t "^I")
  (standard-display-ascii ?\n "$\n")
  )

(defun vi-nolist ()
  "Simulate a :set nolist in Vi."
  (interactive)
  (standard-display-ascii ?\t "\t")
  (standard-display-ascii ?\n "\n")
  )


;; Remember
;; (require 'remember)
;; (autoload 'remember "remember" nil t)
;; (autoload 'remember-region "remember" nil t)



;; Horizontal scroll
;; =======================================
(setq auto-hscroll-mode nil)

(defvar number-to-scroll 1)

(global-set-key [(control ?\,)]
                (lambda (n) (interactive "P") (scroll-right (or n number-to-scroll) nil)))

(global-set-key [(control ?\.)]
                (lambda (n) (interactive "P") (scroll-left (or n number-to-scroll) nil)))

(put 'scroll-left 'disabled nil)


;; Complete (HE) AutoType
;; There are totally 14 funcs available. Here 11 are used.
(global-set-key [(meta ?/)] 'hippie-expand)
(setq hippie-expand-try-functions-list
      '(try-expand-dabbrev
        try-expand-dabbrev-visible
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name-partially
        try-complete-file-name
        try-expand-all-abbrevs
        try-expand-list
        try-expand-line
        try-complete-lisp-symbol-partially
        try-complete-lisp-symbol))


(global-set-key "<" 'skeleton-pair-insert-maybe)
(global-set-key "(" 'skeleton-pair-insert-maybe)
(global-set-key "[" 'skeleton-pair-insert-maybe)
(global-set-key "{" 'skeleton-pair-insert-maybe)
;;(global-set-key "\"" 'skeleton-pair-insert-maybe)
; Single ' is often used in elisp, so don't pair it.
;(global-set-key "\'" 'skeleton-pair-insert-maybe)


(defun my-double-quote (arg)
  "Document string:"
  (interactive "*P")
  (if (and (char-after (point))
           (= ?\" (char-after (point))))
      (forward-char)
      (skeleton-pair-insert-maybe arg)))


(global-set-key "\"" 'my-double-quote)


(setq skeleton-pair t)


(setq tramp-default-method "ftp")



(defun gfn ()
  ""
  (interactive)
  (kill-new (buffer-file-name)))

(defun gbn ()
  ""
  (interactive)
  (kill-new (buffer-name)))

(defun gdn ()
  ""
  (interactive)
  (kill-new (file-name-directory (buffer-file-name))))


(defalias 'im 'imenu-add-menubar-index)


;; codepilot
(load-file (concat mydir "load.el"))



(defface my-bm-face '((((class grayscale) (background light)) (:background "DimGray"))
                         (((class grayscale) (background dark)) (:background "LightGray"))
                         (((class color) (background light)) (:background "yellow"))
                         (((class color) (background dark)) (:foreground "Black" :background "DarkOrange1")))
  "Face used to highlight current line."
  :group 'bm
  )
(setq bm-face 'my-bm-face)

(face-spec-set 'tabbar-default-face
               '((t (:inherit variable-pitch :background "gray72" :foreground "black" :height 0.9))))
(face-spec-set 'tabbar-selected-face
               '((t (:inherit tabbar-default-face :background "gray80" :foreground "blue"
                              :box (:line-width 2 :color "white" :style pressed-button) :weight bold))))
(face-spec-set 'tabbar-unselected-face
               '((t (:inherit tabbar-default-face :background "gray80"
                              :box (:line-width 2 :color "white" :style released-button)))))


;; active codepilot!
(brian-activate-codepilot-cc)
(semantic-mode 1)


;; yasnippet
(add-to-list 'load-path (concat mydir "import/yasnippet-0.6.1c"))
(require 'yasnippet) ;; not yasnippet-bundle
(yas/initialize)
(yas/load-directory (concat mydir "import/yasnippet-0.6.1c/snippets"))



(add-to-list 'load-path (concat mydir "import/AC"))
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories (concat mydir "import/AC/ac-dict"))

(require 'auto-complete-clang)

(setq ac-auto-start nil)
(setq ac-quick-help-delay 0.5)
;; (ac-set-trigger-key "TAB")
;; (define-key ac-mode-map  [(control tab)] 'auto-complete)
;; (define-key ac-mode-map  [(meta ?/)] 'auto-complete)
(defun my-ac-config ()
  (setq-default ac-sources '(ac-source-abbrev ac-source-dictionary ac-source-words-in-same-mode-buffers))
  (add-hook 'emacs-lisp-mode-hook 'ac-emacs-lisp-mode-setup)
  ;; (add-hook 'c-mode-common-hook 'ac-cc-mode-setup)
  (add-hook 'ruby-mode-hook 'ac-ruby-mode-setup)
  (add-hook 'css-mode-hook 'ac-css-mode-setup)
  (add-hook 'auto-complete-mode-hook 'ac-common-setup)
  (global-auto-complete-mode t))
(defun my-ac-cc-mode-setup ()
  ;; (setq ac-sources (append '(ac-source-clang ac-source-yasnippet) ac-sources))
  (setq ac-sources (append '(ac-source-yasnippet) ac-sources))
  )
(add-hook 'c-mode-common-hook 'my-ac-cc-mode-setup)
;; ac-source-gtags
(my-ac-config)
(define-key ac-mode-map [(control tab)] 'ac-complete-clang)


(when (file-directory-p (concat mydir "../opt"))
  (add-to-list 'load-path (concat mydir "../opt"))
  (load-file (concat mydir "myopt.el")))



(require 'smart-mark)

;; (add-hook 'after-init-hook (lambda ()
;;                              (w32-maximize-frame)
;;                              ;; (sit-for 0.2)
;;                              ;; (codepilot-ide)
;;                              )
;;           :append)
