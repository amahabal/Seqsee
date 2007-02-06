; Please have the following lines in your .emacs somewhere, with path set
; appropiately
;(setq load-path
;      (append '("e:/seqsee/Emacs/"
;                "e:/seqsee/Emacs/auctex/")
;              load-path))
;(set-frame-font "-adobe-courier-bold-o-normal--18-180-75-75-m-110-iso8859-15")
;(load "startup")

(load "cperl-mode.el")
(load "seq.el")
(load "cperl6-mode.el")


(defface cperl-pod-face-face
  (` (
      (t (:foreground "yellow" :background "red"))))
  "Font for pods"
  :group 'cperl-faces)

(defface cperl-pod-head-face-face
  (` (
      (t (:foreground "black" :background "red" :bold t))))
  "Font for pod-heads"
  :group 'cperl-faces)

;; sundry

(display-time)

(setq make-backup-files nil)
(load "completion")
(initialize-completions) 
(setq completion-ignore-case nil)

(setq dabbrev-case-fold-search nil)
(setq dabbrev-case-replace nil)

(global-set-key "\`" 'dabbrev-expand)

(global-set-key [f2] 'seqsee-replace)
(global-set-key [f3] 'exit-pvs)
(global-set-key [f4] 'restart-emacs)
(global-set-key [f5] 'prove-pvs-file)


(global-set-key [f6] 'switch-to-buffer)
(global-set-key [f7] 'find-file)
(global-set-key [f9] 'other-window)
(global-set-key [f10] 'save-buffer)
(global-set-key [f11] 'kill-buffer)
(global-set-key [f12] 'save-buffers-kill-emacs)

(setq auto-mode-alist
      (append '(("\\.pm"  . perl-mode)
		("\\.ph"  . perl-mode)
		("\\.pod" . perl-mode)
		("\\.nw"  . perl-mode)
		("\\.p6$"  . cperl6-mode)
		("\\.t$"   . perl-mode) 
		)
	      auto-mode-alist))

(setq auto-mode-alist
      (append '(("\\.xtm" . sgml-mode)
		)
	      auto-mode-alist))

(setq auto-mode-alist
      (append '(("\\.ss" . scheme-mode)
		)
	      auto-mode-alist))

(defun restart-emacs ()
  "Start emacs again b loading the file ~/.emacs"
  (interactive)
  (load "~/.emacs")

)

(autoload 'perl-mode "cperl-mode" "alternate mode for perl" t)
(setq cperl-hairy t)
;(setq cperl6-hairy t)

(define-key global-map [M-S-down-mouse-3] 'imenu)


(defun electric-lisp-newline ()
  "Terminate line and indent next line"
  (interactive)
  (lisp-indent-line)
  (if (equal window-system 'x) (hilit-repaint-command 'S-C-l) nil)
  (newline)
  (lisp-indent-line)
)

(add-hook 'lisp-mode-hook
	  '(lambda ()
	     (progn (local-set-key "\r" 'electric-lisp-newline)
		    )))

(add-hook 'c++-mode-hook
	  '(lambda () (progn (font-lock-mode))))
(add-hook 'scheme-mode-hook
	  '(lambda () (progn (font-lock-mode))))
(add-hook 'emacs-lisp-mode-hook
	  '(lambda () (progn (font-lock-mode))))

	
(load "cperl-mode.el.4.32")
(abbrev-mode 1)
(load "remote1")
(load "menu")

(define-key global-map [mouse-3] 'show-menu)
(x-set-selection 'PRIMARY "")
; (load "lng.el")


(setq outline-minor-mode-prefix "\C-c\C-o")


(add-hook 'LaTeX-mode-hook
	  '(lambda () (progn (font-lock-mode)
			     (outline-minor-mode)
			     )))

(setq TeX-outline-extra
      '(("[ \t]*\\\\\\(bib\\)?item\\b" 7)
	("\\\\bibliography\\b" 2)))

;(set-frame-font "-b&h-lucida sans typewriter-medium-r-normal-sans-18-180-72-72-m-110-iso8859-1")


;(perl-mode)
(define-key cperl-mode-map "\C-a\C-t" 'seq-test-start)
(define-key cperl-mode-map "\C-a\C-c" 'seq-test-start-cl)
(define-key cperl-mode-map "\C-a\C-m" 'seq-comment-method)
;(define-key LaTeX-mode-map "\C-a\C-m" 'seq-method-entry)
(define-key cperl-mode-map "\C-a\C-f" 'seq-comment-file)


(custom-set-variables
 '(cperl-close-paren-offset 4)
 '(cperl-continued-statement-offset 4)
 '(cperl-indent-level 4)
 '(cperl-indent-parens-as-block t)
 '(cperl-tab-always-indent t)
 '(dired-listing-switches "-lR"))

;(custom-set-variables
; '(cperl6-close-paren-offset 4)
; '(cperl6-continued-statement-offset 4)
; '(cperl6-indent-level 4)
; '(cperl6-indent-parens-as-block t)
; '(cperl6-tab-always-indent t))

(setq-default indent-tabs-mode nil)
(setq fill-column 78)
(setq auto-fill-mode t)

(defun perltidy-region ()
    "Run perltidy on the current region."
    (interactive)
    (save-excursion
      (shell-command-on-region (point) (mark) "perltidy -q" nil t)
      (cperl-mode)))

(defun perltidy-all ()
    "Run perltidy on the current region."
    (interactive)
    (let ((p (point)))
      (save-excursion
        (shell-command-on-region (point-min) (point-max) "perltidy -q" nil t)
        )
      (goto-char p)
      (cperl-mode)))

(global-set-key "\M-t" `perltidy-region)
(global-set-key "\M-T" `perltidy-all)

(defun mark-all-pm ()
  (interactive)
  (dired-mark-files-regexp "\\.pm$")
)

(defun mark-all-t ()
  (interactive)
  (dired-mark-files-regexp "\\.t$")
)

(add-hook 'dired-mode-hook
	  '(lambda ()
	     (progn (define-key dired-mode-map "p" 'mark-all-pm)
                    (define-key dired-mode-map "t" 'mark-all-t)
		    )))


(cperl-mode)
(define-abbrev cperl-mode-abbrev-table "docm"
  "" 'seq-comment-method-nd 0)
(define-abbrev cperl-mode-abbrev-table "docmm"
  "" 'seq-comment-method-micro-nd 0)
(define-abbrev cperl-mode-abbrev-table "docmu"
  "" 'seq-comment-multimethod-nd 0)
(define-abbrev cperl-mode-abbrev-table "docp"
  "" 'seq-comment-package-nd 0)
(define-abbrev cperl-mode-abbrev-table "docv"
  "" 'seq-comment-var-nd 0)
(define-abbrev cperl-mode-abbrev-table "sub"
  "" 'seq-sub-body 0)
(define-abbrev cperl-mode-abbrev-table "optg"
  "" 'seq-pull-opt 0)
(define-abbrev cperl-mode-abbrev-table "optgd"
  "" 'seq-pull-opt-with-default 0)

(define-abbrev cperl-mode-abbrev-table "sxt"
  "" 'seq-expansion-test 0)
(define-abbrev cperl-mode-abbrev-table "sxgp"
  "" 'seq-expansion-gp 0)

(define-abbrev cperl-mode-abbrev-table "sxws"
  "" 'seq-expansion-workspace 0)
(define-abbrev cperl-mode-abbrev-table "sxrel"
  "" 'seq-expansion-rel 0)
(define-abbrev cperl-mode-abbrev-table "sxx"
  "" 'seq-expansion-exception 0)
(define-abbrev cperl-mode-abbrev-table "sxxf"
  "" 'seq-expansion-exception-force 0)
(define-abbrev cperl-mode-abbrev-table "sxxt"
  "" 'seq-expansion-exception-type 0)
(define-abbrev cperl-mode-abbrev-table "sxgp"
  "" 'seq-expansion-gp 0)
(define-abbrev cperl-mode-abbrev-table "sxgpnw"
  "" 'seq-expansion-gp-nw 0)
(define-abbrev cperl-mode-abbrev-table "sxaddg"
  "" 'seq-expansion-add-group 0)
(define-abbrev cperl-mode-abbrev-table "sxaddr"
  "" 'seq-expansion-add-rel 0)
(define-abbrev cperl-mode-abbrev-table "sxis"
  "" 'seq-expansion-is-instance 0)
(define-abbrev cperl-mode-abbrev-table "ok"
  "" 'seq-expansion-ok 0)
(define-abbrev cperl-mode-abbrev-table "nok"
  "" 'seq-expansion-nok 0)
(define-abbrev cperl-mode-abbrev-table "mmc"
  "" 'seq-expansion-mmc 0)
(define-abbrev cperl-mode-abbrev-table "sxo"
  "" 'seq-expansion-object 0)

(define-abbrev cperl-mode-abbrev-table "diesok"
  "" 'seq-expansion-diesok 0)

(define-abbrev cperl-mode-abbrev-table "livesok"
  "" 'seq-expansion-livesok 0)

(define-abbrev cperl-mode-abbrev-table "isaok"
  "" 'seq-expansion-isaok 0)

(define-abbrev cperl-mode-abbrev-table "sxtc"
  "" 'seq-stochastic-test-codelet 0)

(define-abbrev cperl-mode-abbrev-table "cmtb"
  "" 'seq-comment-board 0)
(define-abbrev cperl-mode-abbrev-table "cmta"
  "" 'seq-comment-assumption 0)
(define-abbrev cperl-mode-abbrev-table "todo"
  "" 'seq-comment-todo 0)

(define-abbrev cperl-mode-abbrev-table "p6m"
  "" 'seq-perl6-method-or-sub 0)
(define-abbrev cperl-mode-abbrev-table "p6mm"
  "" 'seq-perl6-multimethod-strand 0)


(setq skeleton-end-hook nil)

(defun seqsee-replace (what-to-replace replace-with)
  (interactive (list (read-string "Replace what? " nil)
                     (read-string "Replace with: " nil)))
  (replace-in-files-in-directory "d:/Seqsee/t/" what-to-replace replace-with)
  (replace-in-files-in-directory "d:/Seqsee/lib/" what-to-replace replace-with)
  )
  
(defun replace-in-files-in-directory (dir what-to-replace replace-with)
  (find-file dir)
  (setq default-case-fold-search nil)
  (setq case-fold-search nil)
  (dired-mark-files-regexp "\\.pl$")
  (dired-mark-files-regexp "\\.pm$")
  (dired-mark-files-regexp "\\.t$")
  (dired-do-query-replace-regexp what-to-replace replace-with)
  (setq default-case-fold-search t))

