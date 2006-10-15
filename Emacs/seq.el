
(define-skeleton seq-test-start
  ""
  nil
  "use strict;\n"
  "use blib;\n"
  "use Test::Seqsee;\n";
  "plan tests => " (skeleton-read "Number of tests: ")
  "; \n\n"
  _
)
(define-skeleton seq-test-start-cl
  ""
  nil
  "use strict;\n"
  "use blib;\n"
  "use Test::Seqsee;\n";
  "plan tests => " (skeleton-read "Number of tests: ")
  "; \n\n"
  "use Seqsee;\n"
  "Seqsee->initialize_codefamilies;\n"
  "Seqsee->initialize_thoughttypes;\n"
  > _  
)


(define-skeleton seq-comment-method
  ""
  nil
  "\n#### method "
  (skeleton-read "Name of method: ")
  "\n# " (skeleton-read "One line description: ")
  "\n# usage          :" (skeleton-read "usage: ")
  "\n# description    :" (skeleton-read "description: ")
  "\n# argument list  :" (skeleton-read "argument list: ")
  "\n# return type    :" (skeleton-read "return type: ")
  "\n# context of call:" (skeleton-read "What context should this be called in:  (void/scalar/list/any) :")
  "\n# exceptions     :" (skeleton-read "exceptions raised: ")
  "\n"
)

(define-skeleton seq-comment-method-nd
  ""
  nil
  "\n\n# method: "
  (skeleton-read "Name of method: ")
  "\n# " (skeleton-read "One line description: ")
  "\n#\n" ("description: " "#    " str "\n") 
  "#\n#    usage:\n#     " (skeleton-read "usage: ")
  "\n#\n#    parameter list:\n"   ("Parameter: " "#        " str " - \n")
  "#\n#    return value:\n#      " (skeleton-read "return value: ")
  "\n#\n#    possible exceptions:\n" ("Possible exception: " "#        " str "\n")
  "\n" _
)

(define-skeleton seq-comment-method-micro-nd
  ""
  nil
  "\n\n# method: "
  (skeleton-read "Name of method: ")
  "\n# " (skeleton-read "One line description: ")
  "\n#\n" ("description: " "#    " str "\n")
  "\n" _
)

(define-skeleton seq-comment-multimethod-nd
  ""
  nil
  "\n\n# multi: "
  (skeleton-read "Name of multi method: ")
  " ( " ("Argument: " str ", ") -2 " )"
  "\n# " (skeleton-read "One line description: ")
  "\n#\n" ("description: " "#    " str "\n") 
  "#\n#    usage:\n#     " (skeleton-read "usage: ")
  "\n#\n#    parameter list:\n"   ("Parameter: " "#        " str " - \n")
  "#\n#    return value:\n#      " (skeleton-read "return value: ")
  "\n#\n#    possible exceptions:\n" ("Possible exception: " "#        " str "\n")
  "\n" _
)


(define-skeleton seq-comment-var-nd
  ""
  nil
  "\n# variable: " (skeleton-read "variable name: ") "\n"
  ("Comments about this varaible: " "#    " str "\n"))


(define-skeleton seq-comment-package-nd
  ""
  nil
  "#####################################################\n"
  "#\n"
  "#    Package: " (setq v1 (skeleton-read "Package name: ")) "\n"
  "#\n"
  "#####################################################\n"
  ("Describe this package: " "#   " str "\n")
  "#####################################################\n\n"
  "package " v1 ";\n"
  "use strict;\nuse Carp;\n"
  "use Class::Std;\n"
  "use base qw{" ("Use Base: " str " ") & -1 "};\n" 
  "\n\n"
)

(define-skeleton seq-sub-body
  ""
  nil
  "sub " (skeleton-read "Subroutine name: ") "{\n"
  > "my ( " ("Argument: " str ", ")  -2 " ) = @_;\n"
      _ >
  "\n" "}\n"
)

(define-skeleton seq-method-entry
  ""
  nil
  "\\method{"
  (skeleton-read "Package Name  " )
  "}{"
  (skeleton-read "Method Name  ")
  "}{"
  (skeleton-read "Usage:  ")
  "}{"
  (skeleton-read "Purpose: ")
  "}{"
  (skeleton-read "returns")
  "}{"
  (skeleton-read "p5 signature: ")
  "}{"
  (skeleton-read "p6 signature: ")
  "}{"
  (skeleton-read "throws: ")
  "}{"
  (skeleton-read "comments: ")
  "}\n"
)

(define-skeleton seq-pull-opt
  ""
  nil
  "my $" (setq v1 (skeleton-read "Variable name to pull: "))
  " = $opts_ref->{" (setq v2 (skeleton-read "Variable name key: " v1)) "} or confess \"need " v2 "\";\n"
)

(define-skeleton seq-pull-opt-with-default
  ""
  nil
  "my $" (setq v1 (skeleton-read "Variable name to pull: "))
  " = $opts_ref->{" (skeleton-read "Variable name key: " v1) "} || "
  (skeleton-read "Default: ") ";\n"
)

(define-skeleton seq-expansion-object
  ""
  nil
  (if (string-match "^[0-9]+$" (setq v1 (skeleton-read "What: ")))
      (concat "$SWorkspace::elements[" v1 "]")
      (if (string-match "^$" v1)
          nil
          (concat "$WSO_" v1)
          )
      )
)

(define-skeleton seq-expansion-object-comma
  ""
  nil
  (if (string-match "^[0-9]+$" (setq v1 (skeleton-read "What: ")))
      (concat "$SWorkspace::elements[" v1 "], ")
      (if (string-match "^$" v1)
          nil
          (concat "$WSO_" v1 ", ")
          )
      )
)

(define-skeleton seq-expansion-test
     ""
     nil
     (setq v1 (seq-expansion-object 0))
     "==> " v1
)

(define-skeleton seq-expansion-workspace
  ""
  nil
  "SWorkspace->init({seq => [qw( " _ ")]});\n"
)

(define-skeleton seq-expansion-exception
  ""
  nil
  > "eval {" _ "};\n"
  > "if (my " (skeleton-read "Error-var temporary name: " "$err") " = $EVAL_ERROR) {"
  > _
  > "}\n"
  )

(define-skeleton seq-expansion-exception-force
  ""
  nil
  > "eval {" _ "};\n"
  > "unless ($EVAL_ERROR) {"
  > _
  > "}\n"
  )

(define-skeleton seq-expansion-exception-type
  ""
  nil
  > "if (UNIVERSAL::isa(" (skeleton-read "Error var: " "$err") ", '"
  (skeleton-read "Type: " "SERR::") "\')){\n" > _ "\n" > "}\n"
)

(define-skeleton seq-expansion-gp
  ""
  nil
  > (skeleton-read "Scope: " "my") " " (setq v1 (skeleton-read "Variable: " "$WSO_"))
  " = SAnchored->create(" ("press enter: " (seq-expansion-object-comma) | str) ");\n"
  > "SWorkspace->add_group(" v1 ");\n"
  >
)

(define-skeleton seq-expansion-gp-nw
  ""
  nil
  > (skeleton-read "Scope: " "my") " " (setq v1 (skeleton-read "Variable: " "$WSO_"))
  " = SAnchored->create([ " ("press enter: " (seq-expansion-object-comma) | str) "]);\n"
)

(define-skeleton seq-expansion-rel
  ""
  nil
  > (skeleton-read "Scope: " "my") " " (setq v1 (skeleton-read "Variable: " "$WSO_"))
  " = find_reln(" (seq-expansion-object) ", " (seq-expansion-object) ");\n"
  > v1 "->insert();\n" > 
)




(define-skeleton seq-expansion-add-group
  ""
  nil
  > "SWorkspace->add_group(" (skeleton-read "Which Gp?" "$WSO_") ");\n"
)
(define-skeleton seq-expansion-add-rel
  ""
  nil
  > "SWorkspace->add_rel(" (skeleton-read "Which rel? " "$WSO_") ");\n"
)

(define-skeleton seq-expansion-is-instance
  ""
  nil
  > "UNIVERSAL::isa(" (progn (seq-expansion-object-comma) nil)  "\""(skeleton-read "Type: "  "S") "\") "
)

(define-skeleton seq-expansion-ok
  ""
  nil
  > "ok( " _ ", );\n"
)

(define-skeleton seq-expansion-nok
  ""
  nil
  > "ok( not(" _ "), );\n"
)

(define-skeleton seq-expansion-get
  ""
  nil
  > (progn (seq-expansion-object) nil) "->get_" (skeleton-read "Get what? ") "()"

)

(define-skeleton seq-expansion-set
  ""
  nil
  > (progn (seq-expansion-object) nil) "->set_" (skeleton-read "Set what? ") "(" _ ");\n"

)
(define-skeleton seq-expansion-mmc
  ""
  nil
  > "use Class::Multimethods qw(" (skeleton-read "Which method? ") ");\n"
)

(define-skeleton seq-expansion-diesok
  ""
  nil
  > "dies_ok { " _ "};\n"
  >
)
(define-skeleton seq-expansion-livesok
  ""
  nil
  > "lives_ok { " _ "};\n"
  >
)

(define-skeleton seq-expansion-isaok
  ""
  nil
  > "isa_ok( " (progn (seq-expansion-object) nil) ", " (skeleton-read "What? " "S") ";\n"
  > 
)

(define-skeleton seq-stochastic-test-codelet
  ""
  nil
  > "stochastic_test_codelet( \n"
  > "codefamily => '" (skeleton-read "Codefamily? ") "', \n"
  > "setup      => sub {\n" > _ "\n" > "},\n"
  > "throws     => [ " ("Throws what? " "'" str "', ") "],\n"
  > "post_run   => sub {\n" > _ "\n" > "}\n"
  > ");\n"
)

(defvar insert-date-format "%Y/%m/%d"
  "*Format for \\[insert-date] (c.f. 'format-time-string' for how to
 format)")

(define-skeleton seq-comment-board
  ""
  nil
  "# XXX(Board-it-up): [" 
  (setq v1 (format-time-string insert-date-format (current-time))) "] "
  _ "\n"
)

(define-skeleton seq-comment-todo
  ""
  nil
  "# ToDo: [" (setq v1 (format-time-string insert-date-format (current-time)))
  "] " _ "\n"
)

(define-skeleton seq-comment-assumption
  ""
  nil
  "# XXX(Assumption): [" (setq v1 (format-time-string insert-date-format (current-time)))
  "] " _ "\n"
)

(define-skeleton seq-perl6-method
  ""
  nil
  "method " (skeleton-read "method name: ") " ( "
  (if (string-match "y" (setq v1 (skeleton-read "Has a invocant? " "y")))
      "$self: " "") 
  ") "
)
