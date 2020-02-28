;; test csv

(import (scheme base)
        (scheme case-lambda)
        (cyclone csv)
        (cyclone test))

(define (run-tests)
  (define check-csv-read 
    (case-lambda 
     ((str res)
      (check-csv-read str res #\,))
     ((str res separator)
      (check-csv-read str res separator #\"))
     ((str res separator quotemark)
      (equal? (csv-read-all (make-csv-reader (open-input-string str) separator quotemark))
	      res))))

  (define check-csv-write
    (case-lambda
     ((data target)
      (check-csv-write data target #\,))
     ((data target separator)
      (check-csv-write data target separator #\"))
     ((data target separator quotemark)
      (let ((port (open-output-string)))
	(csv-write-all data (make-csv-writer port separator quotemark))
	(string=? target (get-output-string port))))))

  (test-begin "csv")

  ;; -- reading

  ;; (test-assert (check-csv-read "" '())) - ("Unable to open input memory stream" 22)
  (test-assert (check-csv-read "\n\n" '()))
  (test-assert (check-csv-read "abc" '(("abc"))))
  (test-assert (check-csv-read "a,b,c" '(("a" "b" "c"))))
  (test-assert (check-csv-read "a,b,c\n" '(("a" "b" "c"))))
  (test-assert (check-csv-read "a,b,c\nd,e,f" '(("a" "b" "c") ("d" "e" "f"))))
  (test-assert (check-csv-read "a,b,c\nd,e,f\n" '(("a" "b" "c") ("d" "e" "f"))))
  (test-assert (check-csv-read "\"a\",\"b\",\"c\"" '(("a" "b" "c"))))
  (test-assert (check-csv-read "\"ab\"\"c\",\"b\",\"c\"" '(("ab\"c" "b" "c"))))
  (test-assert (check-csv-read "\"ab\nc\",\"b\",\"c\"" '(("ab\nc" "b" "c"))))
  (test-assert (check-csv-read "\"a,b\nc\",\"b\r\",\"c\"" '(("a,b\nc" "b\r" "c"))))
  (test-assert (check-csv-read "\"aaa\",\"b \r\nbb\",\"ccc\"\nzzz,yyy,xxx" '(("aaa" "b \r\nbb" "ccc") ("zzz" "yyy" "xxx"))))
  (test-assert (check-csv-read " a,  b ,\tc\nd  ,e,f\t" '((" a" "  b " "\tc") ("d  " "e" "f\t"))))
  (test-assert (check-csv-read "0'9\t1797\t1\t1\n0'9\t1803\t1\t1\n0'9\t1816\t2\t2" '(("0'9" "1797" "1" "1") ("0'9" "1803" "1" "1") ("0'9" "1816" "2" "2")) #\tab))
  (test-assert (check-csv-read "0'9	1797	1	1
0'9	1803	1	1
0'9	1816	2	2" '(("0'9" "1797" "1" "1") ("0'9" "1803" "1" "1") ("0'9" "1816" "2" "2")) #\tab))

					; what do we get for blank lines?
					; -- filtered out
  (test-assert (check-csv-read "a,b,c\n\nd,e,f" '(("a" "b" "c") ("d" "e" "f"))))

					; what do we get if we include a line with no commas?
					; -- comments can be filtered out later
  (test-assert (check-csv-read "a,b,c\n#comments?\nd,e,f" '(("a" "b" "c") ("#comments?") ("d" "e" "f"))))

					; trailing commas / empty fields
  (test-assert (check-csv-read "a,,c\n,e,f" '(("a" "" "c") ("" "e" "f"))))
  (test-assert (check-csv-read "a,,c\n,e,f\n\n\n" '(("a" "" "c") ("" "e" "f"))))
  (test-assert (check-csv-read "a,b,c,\nd,e,f," '(("a" "b" "c" "") ("d" "e" "f" ""))))
  (test-assert (check-csv-read ",,," '(("" "" "" ""))))
  (test-assert (check-csv-read "\"a\",\"\",\"c\"\n\"\",\"e\",\"f\"" '(("a" "" "c") ("" "e" "f"))))
  (test-assert (check-csv-read "\"a\",\"b\",\"c\",\"\"\n\"d\",\"e\",\"f\",\"\"" '(("a" "b" "c" "") ("d" "e" "f" ""))))
  (test-assert (check-csv-read "\"\",\"\",\"\",\"\"" '(("" "" "" ""))))

					; does unicode work?
  (test-assert (check-csv-read "good,ভালো,üöß" '(("good" "ভালো" "üöß"))))

					; check zeros are accepted
  (test-assert (check-csv-read "ab,c\x0;,d" '(("ab" "c\x0;" "d"))))

					; alternative separator
  (test-assert (check-csv-read "a,b,c\nd,e,f" '(("a,b,c") ("d,e,f")) #\tab))
  (test-assert (check-csv-read "a\tb\tc\nd\te\tf" '(("a" "b" "c") ("d" "e" "f")) #\tab))
  (test-assert (check-csv-read "\"a|b\nc\"|\"b\r\"|\"c\"" '(("a|b\nc" "b\r" "c")) #\|))
  (test-assert (check-csv-read "\"a|,\tb\nc\"|\"b\r\"|\"c\"" '(("a|,\tb\nc" "b\r" "c")) #\|))

					; change the quote mark
  (test-assert (check-csv-read "'ab\"c','b','c'" '(("ab\"c" "b" "c")) #\, #\'))

					; different line endings
  (test-assert (check-csv-read "a,b,c\r\nd,e,f\rg,h,i\nj,k,l" 
			       '(("a" "b" "c") ("d" "e" "f") ("g" "h" "i") ("j" "k" "l"))))

					; JSON example from csv-spectrum
  (test-assert (check-csv-read "1,\"{\"\"type\"\": \"\"Point\"\", \"\"coordinates\"\": [102.0, 0.5]}\"" '(("1" "{\"type\": \"Point\", \"coordinates\": [102.0, 0.5]}"))))

					; what could go wrong?
  (test-error (csv-read-all (make-csv-reader (open-input-string "a,\"b,c"))))
  (test-error (csv-read-all (make-csv-reader (open-input-string "a,b\"c,d"))))
  (test-error (csv-read-all (make-csv-reader (open-input-string "a,\"b\"d,c"))))
  (test-error (make-csv-reader (current-output-port)))
  (test-error (make-csv-reader (current-input-port) "abc"))


  ;; -- writing
  
  (test-assert (check-csv-write '(("a" "b" "c")) "a,b,c\n"))
  (test-assert (check-csv-write '(("a" "b" "c") ("def" "g")) "a,b,c\ndef,g\n"))
  (test-assert (check-csv-write '(("a" "b" "c") ("d,ef" "g")) "a,b,c\n\"d,ef\",g\n"))
  (test-assert (check-csv-write '(("a\r" "\"b" "c") ("d,\nef" "g")) "\"a\r\",\"\"\"b\",c\n\"d,\nef\",g\n"))
  (test-assert (check-csv-write '(("a\"b" "c\r\nd")) "a\"b\t'c\r\nd'\n" #\tab #\'))
  (test-assert (check-csv-write '(("a'b")) "'a''b'\n" #\tab #\'))
  (test-assert (check-csv-write (list (list 'a 'bc) (list 12.3 "12,3"))
				"a,bc\n12.3,\"12,3\"\n"))

  (test-end))

(run-tests)
