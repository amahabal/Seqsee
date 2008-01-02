(require 'easymenu)
(require 'imenu)
(easy-menu-define my-additions-menu global-map "My Additions"
		  '("MyAdditions"
                    ["Show Uncommited Changes" seq-svn-diff t]
                    ["Search Seqsee Codebase" seq-search-codebase t]
                    ["Insert Category Creation Code" seqsee-category-type t]
                    ["Insert CHANGES block" seqsee-CHANGES-block t]
                    ["Insert Copyright" seqsee-Copyright-block t]
                    ["Reload emacs code" restart-emacs t]
                    ["Global replace in lib/" seqsee-replace-lib t]
                    ["Global replace in t/" seqsee-replace-t t]
))

(setq tool-bar-map (make-sparse-keymap))
(tool-bar-add-item-from-menu 'find-file "new")
(tool-bar-add-item-from-menu 'menu-find-file-existing "open")
  (tool-bar-add-item-from-menu 'kill-this-buffer "close")
  (tool-bar-add-item-from-menu 'save-buffer "save" nil
			       :visible '(or buffer-file-name
					     (not (eq 'special
						      (get major-mode
							   'mode-class)))))
  (tool-bar-add-item-from-menu (lookup-key menu-bar-edit-menu [cut])
			       "cut" nil
			       :visible '(not (eq 'special (get major-mode
								'mode-class))))
  (tool-bar-add-item-from-menu (lookup-key menu-bar-edit-menu [copy])
			       "copy")
  (tool-bar-add-item-from-menu (lookup-key menu-bar-edit-menu [paste])
			       "paste" nil
			       :visible '(not (eq 'special (get major-mode
								'mode-class))))
(tool-bar-add-item "seqsee-right-arrow" 'seq-svn-diff 'fookey
                   :help "Show uncommited changes"
                   )
(tool-bar-add-item "seqsee-search" 'seq-search-codebase 'searchcb
                   :help "Search Seqsee Codebase"
                   )
(tool-bar-add-item "delete" 'kill-line 'kill-line-menu
                   :help "^k"
                   )
(tool-bar-add-item "jump-to" 'execute-extended-command 'execute-extended-command-menu
                   :help "M-x"
                   )
(tool-bar-add-item "refresh" 'perltidy-all 'perltidy-all-menu
                   :help "perltidy-all"
                   )
(tool-bar-add-item "zoom-out" 'seq-formula-insert 'seq-formula-insert-menu
                   :help "Insert a formula"
                   )
(tool-bar-add-item "seqsee-right-arrow" 'dabbrev-expand 'dabbrev-expand-menu
                   :help "dabbrev-expand"
                   )
