(require 'easymenu)
(require 'imenu)
(easy-menu-define my-additions-menu global-map "My Additions"
		  '("MyAdditions"
                    ["Show Uncommited Changes" seq-svn-diff t]
                    ["Search Seqsee Codebase" seq-search-codebase t]
))

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
