;; 9 Oct 2000. Abhijeet Mahabal
;; A mode for the tower of hanoi
;; My first emacs mode!

(defvar hanoi-mode-hook nil
  "No extra stuff... curently")

(defvar hanoi-mode-syntax-table nil
  "Nothing right now")


(defun hanoi-mode ()
  "Major mode for showing the solution of Hanoi..."
  (interactive)
  (kill-all-local-variables)
  (make-local-variable 'SIZE)
  (hanoi-fill-buffer 20 50 ?.)
  (setq mode-name "Hanoi")
  (setq major-mode 'hanoi-mode)
  (run-hooks 'hanoi-mode-hooks)
)

(defun hanoi-fill-buffer (lines cols char)
  (erase-buffer)
  (insert (make-string cols char))
  (insert "\n")
  (insert (make-string cols char))
)
(defun hanoi-insert (lineno offset args)
  (goto-line lineno)
  (beginning-of-line)
  (forward-char 10)
  (insert args)
)

(defun hanoi-insert-disk (pole size pos)
  (let ((line (- 10 pos))
	(left (- (* 20 pole) size))
	)
    (hanoi-insert line left (make-string (* size 2) ?x))
    )
)

(defun hanoi-example-insert ()
  (interactive)
  (hanoi-insert-disk 2 10 5)
)

    




