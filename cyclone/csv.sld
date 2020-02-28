;; csv library : functions to read/write CSV data from/to a port.
;;
;; Some minimal customisation is available:
;; -- choosing the separator character, e.g. tab instead of comma
;; -- choosing the quote character, e.g. single instead of double-quote
;;
;; RFC4180 compliant - http://tools.ietf.org/html/rfc4180
;; However:
;; -- any of "\r\n" "\r" "\n" are accepted as line breaks, outside of quoted
;;    fields.
;;
;; During writing:
;; -- converts Scheme symbol to a string
;; -- writes strings character by character, quoting if necessary
;; -- writes all other data using 'display'
;;
;; Left to caller:
;; -- headers
;; -- type conversion
;; -- comments
;;
;; Consider adding extensions:
;; -- lazy quotes (i.e. fields with a " inside them, but not extended, like x,a"b,y)
;; -- changing escape character (e.g. not "" but \")
;; -- csv-for-each applying a function on each record 
;;
;; Written by Peter Lane, 2018

(define-library (cyclone csv)
  (export make-csv-reader
          csv-read
          csv-read-all
          make-csv-writer
          csv-write
          csv-write-all)
  (import (scheme base)
          (scheme case-lambda)
          (scheme char)
          (scheme write)) 

  (begin
    (define-record-type <csv-port>
      (new-port port separator quotechar)
      csv-port?
      (port port-of)
      (separator separator-of)
      (quotechar quotechar-of))

    ;; create a full reader, with the port and separator
    (define make-csv-reader 
      (case-lambda
       (() 
	(make-csv-reader (current-input-port)))
       ((port) 
	(make-csv-reader port #\,))
       ((port separator)
	(make-csv-reader port separator #\"))
       ((port separator quotechar)
	(if (and (input-port? port)
		 (char? separator)
		 (char? quotechar))
	    (new-port port separator quotechar)
	    (error "Invalid arguments: needs input port and characters" 
		   port separator quotechar)))))

    ;; reads a single line, returning a list of fields or
    ;; eof if the input-port is empty or at end
    (define csv-read 
      (case-lambda
       (()
	(csv-read (new-port (current-input-port) #\, #\")))
       ((reader)
	(read-record reader))))

    ;; uses csv-read to read all lines until eof reached
    ;; returns a list of results
    (define csv-read-all
      (case-lambda
       (()
	(csv-read-all (new-port (current-input-port) #\, #\")))
       ((reader)
					; read from reader
	(let loop ((result '())
		   (line (read-record reader)))
	  (if (eof-object? line)
	      (reverse result)
	      (loop (if (or (null? line) (equal? line '(""))) ; ignore empty lines
			result
			(cons line result))
		    (read-record reader)))))))

    (define (read-field reader)
      (define COMMA (separator-of reader))
      (define QUOTECHAR (quotechar-of reader))
      (define (text-data? c)
	(and (not (eof-object? c))
	     (not (char=? c COMMA))
	     (not (char=? c QUOTECHAR))
	     (not (memq c '(#\newline #\return)))))
      (define (extended-char? c)
	(not (eof-object? c))) ; too generous? accept anything not already caught
					;
      (cond ((eof-object? (peek-char (port-of reader)))
	     "")
	    ((char=? QUOTECHAR (peek-char (port-of reader)))
					; escaped version
	     (read-char (port-of reader))
	     (let loop ((chars '())) 
	       (cond ((eof-object? (peek-char (port-of reader)))
		      (error "Ended too soon" reader))
		     ((char=? QUOTECHAR (peek-char (port-of reader)))
		      ;; double " or finish?
		      (read-char (port-of reader))
		      (cond ((eof-object? (peek-char (port-of reader)))
			     (list->string (reverse chars)))
			    ((char=? QUOTECHAR (peek-char (port-of reader))) ; double quotechar
			     (loop (cons (read-char (port-of reader)) chars))) ; continue field
			    ((memq (peek-char (port-of reader)) (list #\newline #\return COMMA))
			     (list->string (reverse chars))) 
			    (else
			     (error "Extended field must finish field" (read-char (port-of reader))))))
		     ((extended-char? (peek-char (port-of reader)))
		      (loop (cons (read-char (port-of reader)) chars)))
		     (else
		      (error "Illegal character" (read-char (port-of reader)))))))
	    (else ; non-escaped version
	     (let loop ((chars '())) 
	       (cond ((eof-object? (peek-char (port-of reader))) ; field ends with file
		      (list->string (reverse chars)))
		     ((text-data? (peek-char (port-of reader)))
		      (loop (cons (read-char (port-of reader)) chars)))
		     ((memq (peek-char (port-of reader))         ; field ends on comma/newline
			    (list #\newline #\return COMMA))
		      (list->string (reverse chars)))
		     (else
                      (error "Illegal character" (read-char (port-of reader)))))))))

					; Read field *[, field]
    (define (read-record reader)
      (if (eof-object? (peek-char (port-of reader)))
	  (read-char (port-of reader))
	  (let loop ((contents (list (read-field reader))))
	    (cond ((eof-object? (peek-char (port-of reader)))
		   (reverse contents))
		  ((char=? #\newline (peek-char (port-of reader)))        ; "\n" 
		   (read-char (port-of reader))
		   (reverse contents))
		  ((char=? #\return (peek-char (port-of reader)))         ; "\r"
		   (read-char (port-of reader))
		   (when (char=? #\newline (peek-char (port-of reader)))  ; "\r\n"
		     (read-char (port-of reader)))
		   (reverse contents))
		  ((char=? (separator-of reader) (peek-char (port-of reader)))
		   (read-char (port-of reader))
		   (loop (cons (read-field reader) contents)))
		  (else
		   (error "Invalid end of field" contents))))))

					; Create a writer with port and separator
    (define make-csv-writer
      (case-lambda
       (() 
	(make-csv-writer (current-output-port)))
       ((port) 
	(make-csv-writer port #\,))
       ((port separator) 
	(make-csv-writer port #\, #\"))
       ((port separator quotechar)
	(if (and (output-port? port)
		 (char? separator)
		 (char? quotechar))
	    (new-port port separator quotechar)
	    (error "Invalid arguments: needs input port and characters" 
		   port separator quotechar)))))

    (define csv-write
      (case-lambda
       ((line)
	(csv-write line (new-port (current-output-port) #\, #\")))
       ((line writer)
	(define (csv-write-field field)
	  (define QUOTECHAR (quotechar-of writer))
	  (define (use-quotes?) 
	    (let ((chars (string->list field)))
	      (or (memq (separator-of writer) chars)
		  (memq #\newline chars)
		  (memq #\return chars)
		  (memq (quotechar-of writer) chars))))
					;
	  (cond ((symbol? field) 
		 (csv-write-field (symbol->string field)))
		((and (string? field) (use-quotes?))
		 (write-char QUOTECHAR (port-of writer))
		 (for-each (lambda (c)
			     (write-char c (port-of writer))
			     (when (char=? c QUOTECHAR)
			       (write-char c (port-of writer))))
			   (string->list field))
		 (write-char QUOTECHAR (port-of writer)))
		(else ; all other data types
                 (display field (port-of writer)))))
					;
	(unless (null? line)
	  (csv-write-field (car line))
	  (for-each (lambda (field)
		      (write-char (separator-of writer) (port-of writer))
		      (csv-write-field field))
		    (cdr line))
	  (newline (port-of writer))))))

    (define csv-write-all
      (case-lambda
       ((data)
	(csv-write-all data (new-port (current-output-port) #\, #\")))
       ((data writer)
	(for-each (lambda (line) (csv-write line writer))
		  data))))))
