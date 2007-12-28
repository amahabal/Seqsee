(require 'easymenu)
(require 'imenu)
(easy-menu-define global-menu global-map "Menu for CPerl mode"
		  '("Translate"
		    ["translate to german" translate-buffer-to-german t]
		    ["translate to french" translate-buffer-to-french  t]
))

(defun show-menu ()
  (interactive)
  (funcall (car (x-popup-menu t
			      '("" 
				("B" 
				 ("Search Google" search-google)
				 ("Search Roget" search-roget)
				 ("Search for rhymes" search-rhyme)
				 ("Search Encarta" search-encarta)
				 ("Translate Buffer to German" translate-buffer-to-german)
				 ("Translate Buffer to French" translate-buffer-to-french)
				 ))
			      
			      )
		)

	   )
)

(defun show-menu-temp ()
  (interactive)
  (funcall (car (x-popup-menu t
			      '("" 
				("B" 
				 ("Search" show-string)
				 ("Search Google" search-google)
				 ("Search Roget" search-roget)
				 ("Search for rhymes" search-rhyme)
				 ("Search Encarta" search-encarta)
				 ("Translate Buffer to German" translate-buffer-to-german)
				 ("Translate Buffer to French" translate-buffer-to-french)
				 ))
			      
			      )
		)

	   )
)


(defun show-string ()
  (setf l (list "THE STRING" ((selection-or-word) "")))
  (x-popup-dialog t l)
)
















