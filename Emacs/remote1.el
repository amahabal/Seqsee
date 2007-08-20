(require 'ffap)
(require 'cl)


(defun replace (strold p1 p2)
  (let ((strnew ""))
    (while (> (length strold) 0)
      (setf c (subseq strold 0 1))
      (setf strold (subseq strold 1))
      (setf strnew (concat strnew
			   (if (equal c p1)
			       p2
			     c
			     )
			   )
	    )
      )
    strnew
    )
)

(defun escape (str)
  (setq buffer str)
  (setq buffer (replace buffer " " "+"))
  (setq buffer (replace buffer "&" "+"))
  (setq buffer (replace buffer "," "+"))
  (setq buffer (replace buffer "\n" "+"))
  buffer
)

(defun translate-buffer-to-german ()
  "Translate english text to german"
  (interactive)
  (end-of-buffer)
  (setq buffer (buffer-substring 1 (point)))
  (setq buffer (replace buffer " " "+"))
  (setq buffer (replace buffer "&" "+"))
  (setq buffer (replace buffer "," "+"))
  (setq buffer (replace buffer "\n" "+"))
  (go-search-translate buffer)
)
(defun translate-buffer-to-french ()
  "Translate english text to german"
  (interactive)
  (end-of-buffer)
  (setq buffer (buffer-substring 1 (point)))
  (setq buffer (replace buffer " " "+"))
  (setq buffer (replace buffer "&" "+"))
  (setq buffer (replace buffer "," "+"))
  (setq buffer (replace buffer "\n" "+"))
  (go-search-translate2 buffer)
)


(defun go-url (url)
  "go to a specific url"
  (interactive)
  (shell-command (concat "netscape -remote 'openURL(" url ")' 2>&/dev/null"))
)

(defun selection-or-word ()
  (let ( (word (ffap-string-at-point "text-mode") )
	 (sel (x-get-selection))
	 )
    (x-set-selection 'PRIMARY "")
    (if (> (length sel) 0) sel word)
    )
)

(defun get-word-at-point ()
  (interactive)
  (save-excursion
    (backward-word 1)
    (let ((beg (point)))
      (forward-word 1)
      (buffer-substring beg (point))
      )
    )
  )      

(defun search-google ()
  "Search current word on google"
  (interactive)
  (go-url (concat "http://www.google.com/search?q=" 
		  ;;(ffap-string-at-point "-a-zA-Z0-9.")
		  ;;(escape (x-get-selection))
		  (escape (selection-or-word))
		  )
	  )
  )

(defun search-roget ()
  "Search current word on rogets thesaurus"
  (interactive)
  (go-url (concat "http://machaut.uchicago.edu/cgi-bin/ROGET.sh?word=" 
		  ;;(ffap-string-at-point "-a-zA-Z0-9.")
		  (escape (selection-or-word))
		  )
	  )
  )

(defun search-rhyme ()
  "Search current word in a rhyming dictionary"
  (interactive)
  (go-url (concat "http://rhyme.lycos.com/r/rhyme.cgi?Word=" 
		  ;;(ffap-string-at-point "-a-zA-Z0-9.")
		  (escape (selection-or-word))
		  "&typeofrhyme=perfect&org1=syl&org2=l"
		  )
	  )
  )





(defun go-search-translate (word)
  "find description on encarta"
  (interactive)
  (go-url (concat "http://www.systranlinks.com/systran/cgi?partner=demo-SystranSoft&lp=en_de&urltext=" word))
)

(defun go-search-translate2 (word)
  "find description on encarta"
  (interactive)
  (go-url (concat "http://www.systranlinks.com/systran/cgi?partner=demo-SystranSoft&lp=fr_en&urltext=" word))
)

(defun search-encarta ()
  "Search current word on encarta"
  (interactive)
  (go-url (concat "http://encarta.msn.com/find/search.asp?search=" 
		  ;;(ffap-string-at-point "-a-zA-Z0-9.")
		  (escape (selection-or-word))
		  )
	  )
  )





