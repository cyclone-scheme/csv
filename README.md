# csv

## Index 
- [Intro](#Intro)
- [Dependencies](#Dependencies)
- [Test dependencies](#Test-dependencies)
- [Foreign dependencies](#Foreign-dependencies)
- [API](#API)
- [Examples](#Examples)
- [Author(s)](#Author(s))
- [Maintainer(s)](#Maintainer(s))
- [Version](#Version) 
- [License](#License) 
- [Tags](#Tags) 

## Intro 
A CSV reader/writer library. RFC4180 compliant - http://tools.ietf.org/html/rfc4180 - but allowing:

* choice of separator character, e.g. tab instead of comma
* choice of quote character, e.g. single instead of double-quote
* "CR LF", "CR" or "LF" are all accepted as line endings when reading

The CSV reader/writer uses a standard input or output port. Records are retrieved or written as lists of field values. Fields are always read as strings. Fields are written using `display` unless they are strings needing quoting, when they are written character by character, or symbols, which are first converted to strings.

## Dependencies 
None

## Test-dependencies 
None

## Foreign-dependencies 
None

## API 

### (cyclone csv)

#### [procedure]   `(make-csv-reader)`
Creates a csv-reader object:

* no arguments: uses current input port, comma as separator and double-quote for quote character
* one argument: specifies input port
* two arguments: specifies input port and separator character
* three arguments: specifies input port, separator character and quote character

#### [procedure]   `(csv-read)`
Reads a single record (list of fields) from given reader, or current-input-port if no reader given.

#### [procedure]   `(csv-read-all)`
Reads a list of records (list of fields) from given reader, or
current-input-port if no reader given.

```scheme
> (import (cyclone csv) (scheme file))
> (with-input-from-file "data.csv" (lambda () (csv-read-all)))
(("123" "field 2" "456") ("789" "see, comma" "12"))
```

#### [procedure]   `(make-csv-writer)`
Creates a csv-writer object:

* no arguments: uses current-output-port, comma as separator and double-quote for quote character
* one argument: specifies output port
* two arguments: specifies output port and separator character
* three arguments: specifies output port, separator character and quote character

#### [procedure]   `(csv-write line)`
Writes a single record (list of fields) in CSV format:

* one argument: the record, writes to the current-output-port with comma as separator and double-quote for quote character
* two arguments: the record and a csv-writer object

#### [procedure]   `(csv-write-all data)`
Writes a list of records in CSV format:

* one argument: the records, writes to the current-output-port with comma as separator and double-quote for quote character
* two arguments: the records and a csv-writer object

```scheme
> (import (cyclone csv) (scheme file))
> (with-output-to-file "data.csv" 
   (lambda () (csv-write-all '((123 "field 2" 456) (789 "see, comma" 012)))))
```
```shell
$ more data.csv
123,field 2,456
789,"see, comma",12
```

## Examples
```scheme
(import (scheme base)
        (cyclone csv))

(with-output-to-file "data.csv" 
   (lambda () (csv-write-all '((123 "field 2" 456) (789 "see, comma" 012)))))
```

```shell
$ more data.csv
123,field 2,456
789,"see, comma",12
```

```scheme
(with-input-from-file "data.csv" (lambda () (csv-read-all)))
=>
(("123" "field 2" "456") ("789" "see, comma" "12"))
```

## Author(s)
Peter Lane

## Maintainer(s) 
Arthur Maciel <arthurmaciel at gmail dot com>

## Version 
0.1.1

## License 
BSD

## Tags 
