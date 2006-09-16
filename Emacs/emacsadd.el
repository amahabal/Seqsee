(define-skeleton add-key
  ""
  none
  "(define-key perl-mode-map"
  _
  "  '"
  (skeleton-read "Name: ")
  ")" \n
)

(define-skeleton add-menu
  ""
  none
  "(define-key menu-map [ " _ "] (\""
  (skeleton-read "display string: ")
  "\" . '" (skeleton-read "Name: ")
  ")" \n
)

(global-set-key "\C-q" 'add-key)
(global-set-key "\C-w" 'add-menu)
  














