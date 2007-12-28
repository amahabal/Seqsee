(setq dabbrev-abbrev-char-regexp "\\sw\\|\\s_\\|[][]")

(abbrev-mode 1)

(load "~/emacs/tkadd.el")

;; ALL THE KEY BINDINGS FOR THE EXTENDED PERL MODE OCCUR HERE

;;(let ((map (nconc (make-sparse-keymap) perl-mode-map2))
;;      (menu-map (make-sparse-keymap "PERL")))
;;  (define-key perl-mode-map2 [menu-bar perl] (cons "PERL" menu-map))

;;  (define-key menu-map [new]      '("Constuctor ^c^cn" . perl-new))
;;  (define-key menu-map [packsub]  '("Sub in a package ^c^cS" . perl-pack-fun))
;;  (define-key menu-map [package]     '("Package ^c^cp" . perl-package))
;;  (define-key menu-map [for]        '("FOR  ^c^cr" .perl-for))
;;  (define-key menu-map [fl]         '("Start line" . perl-start))
;;  (define-key menu-map [foreach]    '("Foreach ^c^cf" . perl-foreach))
;;  (define-key menu-map [subroutine] '("Subroutine ^c^cs" . perl-sub))



;;  (define-key perl-mode-map2 "\C-c\C-cs" 'perl-sub)
;;  (define-key perl-mode-map2 "\C-c\C-cS" 'perl-pack-fun)
;;  (define-key perl-mode-map2 "\C-c\C-ci" 'perl-input)
;;  (define-key perl-mode-map2 "\C-c\C-cr" 'perl-for)
;;  (define-key perl-mode-map2 "\C-c\C-cf" 'perl-foreach)
;;  (define-key perl-mode-map2 "\C-c\C-cp" 'perl-package)
;;  (define-key perl-mode-map2 "\C-c\C-cn" 'perl-new)
;;  (define-key perl-mode-map2 "\C-c\C-cv" 'perl-var)

  ;; FOR TOOL KIT ;; Prefix ^t^t

;;  (define-key perl-mode-map2 "\C-t\C-tb" 'tk-button)
;;  (define-key perl-mode-map2 "\C-t\C-td" 'tk-dial)
;;  (define-key perl-mode-map2 "\C-t\C-tf" 'tk-frame)
;;  (define-key perl-mode-map2 "\C-t\C-te" 'tk-entry)
;;  (define-key perl-mode-map2 "\C-t\C-tc" 'tk-canvas)

  ;; FOR NETS

 (define-key perl-mode-map "\C-n\C-nc" 'perl-client)
 (define-key perl-mode-map "\C-n\C-ns" 'perl-server)
 (define-key perl-mode-map "\C-n\C-nl" 'perl-server-loop)


;;  (define-key menu-map [tk-start] '("TK start line" . tk-main))



  ;; GENERAL

;;  (define-key perl-mode-map2 "`"     'dabbrev-expand)
  
;;)

(define-skeleton perl-start
  "Gives the first line of the perl program"
  nil
  "\#!/usr/bin/perl -w"  _
)


(define-skeleton perl-for 
  ""
  nil
  "for("
  (setq v1 (skeleton-read "Variable: "))
  "=" (skeleton-read "Initial value: ")
  ";" v1 "<" _ ";" v1 "++){" \n \n "}" \n
)

(define-skeleton perl-foreach
  ""
  nil
  "foreach "
  (skeleton-read "Variable: ")
  " (" _ "){" \n \n "}" \n
)


(define-skeleton perl-sub
  ""
  nil
  \n
  "\# subroutine "
  (setq v1 (skeleton-read "Function name: ")) \n
  "sub " v1 " {" \n
  (if (string= (setq v2 (skeleton-read "Any Arguments? [y/n]")) "y")
      "local(" "")
  _
  (if (string= v2 "y") " ) = @_;" "")
  \n \n "}" \n
  "\# end of subroutine " v1 \n
)

(define-skeleton  perl-package
  ""
  nil
  "package "
  (skeleton-read "Package Name: ")
  ";" \n
  "require Exporter;" \n
  "@ISA = qw(Exporter); " \n
  "@EXPORT = qw();" \n
  "@EXPORT_OK = qw();" \n
  )

(define-skeleton perl-new
  ""
  nil
  \n
  "\# Constructor " \n
  "sub new{ " \n
  "my $class = shift; " \n  
  "my params = @_; " \n
  "my $self={}; " \n 
  _
   "bless $self,$class;" \n
   "return $self;" \n
   "}" \n
   "\# end of constructor \r" \n
   )
        
(define-skeleton perl-pack-fun
  ""
  nil
  \n
  "\# subroutine "
  (setq v1 (skeleton-read "Function name: ")) \n
  "sub " v1 " {" \n
  "my $self = shift;" \n
  (if (string= (setq v2 (skeleton-read "Any Arguments? [y/n]")) "y")
      "local(" "")
  _
  (if (string= v2 "y") " ) = @_;" "")
  \n \n "}" \n
  "\# end of subroutine " v1 \n
  )

(define-skeleton perl-input
  ""
  nil
  "chop( "
  (skeleton-read "Variable name: ")
  "= <>) ; "
)

(define-skeleton perl-var
  ""
  nil
  "local( " _ ");"
)

(define-skeleton perl-client 
  ""
  nil
  "$remote = shift || '" (skeleton-read "REMOTE ADDRESS  :")
  "';" \n
  "$port = shift || " (skeleton-read "PORT NUMBER  :")
  ";" \n
  "if($port =~ \/\\D\/) { $port = getservbyname($port, 'tcp');}" \n
  "die \"No port\" unless($port);" \n
  "$iaddr = inet_aton($remote);" \n
  "$paddr = sockaddr_in($post, $iaddr); " \n \n
  "$proto = getprotobyname('tcp');" \n
  "socket(" (setq v1 (skeleton-read "SOCKET DESCRIPTOR  :")) 
  ", PF_INET,SOCK_STREAM,$proto);" \n
  "connect(" v1 ",$paddr);" \n
)

(define-skeleton perl-server 
  ""
  nil
  "my $port = shift ||" (skeleton-read "PORT NUMBER :") ";" \n
  "$proto = getprotobyname('tcp');" \n
  "socket(" (setq v1 (skeleton-read "SOCKET DESCRIPRTOR :"))
  ",PF_INET,SOCK_STREAM,$proto);" \n
  "setsockopt(" v1 ",SOL_SOCKET,SO_REUSEADDR,pack(\"1\",1));" \n
  "bind(" v1 ",sockaddr_in($port,INADDR_ANY));" \n
  "listen(" v1 ",SOMAXCONN);" \n
)

(define-skeleton perl-server-loop 
  ""
  nil
  "for(;$paddr=accept("
  (setq v1 (skeleton-read "CLIENT DESCRIPTOR :"))
  "," (setq v2 (skeleton-read "SERVER DESCRIPTOR :"))
  ");close " v1 "){" \n
  "my($port,$iaddr) = sockaddr_in($paddr);" \n
  "my $name = getprotobyname($iaddr,AF_INET);" \n
)
(define-skeleton perl- 
  ""
  nil
)
(define-skeleton perl- 
  ""
  nil
)
(define-skeleton perl- 
  ""
  nil
)














