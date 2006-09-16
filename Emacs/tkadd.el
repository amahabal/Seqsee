(define-skeleton tk-main
  ""
  nil
  "use Tk;" 
  \n
  (if (string= (skeleton-read "Include Color Editor ?[y/n]")
	       "y")
      "use Tk::ColorEditor;" ""
      )
  (if (string= (skeleton-read "Include File select?[y/n]")
	       "y")
      "use Tk::FileSelect;" ""
      )
  (if (string= (skeleton-read "Include Balloon ?[y/n]")
	       "y")
      "use Tk::Balloon;" ""
      )
  (if (string= (skeleton-read "Include Dialogbox ?[y/n]")
	       "y")
      "use Tk::DialogBox;" ""
      )
  "\$MW = new MainWindow ; " 
  \n
)


(define-skeleton tk-button
  ""
  nil
  (skeleton-read "WidgetName: ")
  " = "
  (skeleton-read "Frame name: ")
  "->Button(-text => \""
  (skeleton-read "Text: ")
  "\"," \n " -command => " _ 
  ")->pack(-side => 'top');"
)

(define-skeleton tk-frame
  ""
  nil
  (skeleton-read "WidgetName: ")
  " = "
  (skeleton-read "Frame name: ")
  "->Frame()->pack(-side => 'top');"
)

(define-skeleton tk-entry
  ""
  nil
  (skeleton-read "WidgetName: ")
  " = "
  (skeleton-read "Frame Name: ")
  "->Entry(" \n
  "-width => 20," \n
  "-textvariable => \\"
  (skeleton-read "Variable: ")
  ")->pack(-side => 'top');"
)
  
(define-skeleton tk-canvas
  ""
  nil
  (skeleton-read "WidgetName: ")
  " = "
  (skeleton-read "Frame Name: ")
  "->Canvas(" \n
  "-width => 100," \n
  "-height => 100)->pack(-side => 'top');" 
)

 
(define-skeleton tk-dial
  ""
  nil
  (skeleton-read "WidgetName: ")
  " = "
  (skeleton-read "Frame :")
  "->Dial(-margin => 20," \n
  "-radius => 48," \n
  "-min => 0," \n
  "-max => 100," \n
  "-value => 0," \n
  "-format => '%d');"
)
  


























