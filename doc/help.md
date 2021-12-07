# Overview

CX processes a pipeline of commands which transform tabular data.

A pipeline's commands are separated by "`//`" -- mnemonic: Unix shell pipe "`|`".

Some commands have pipelines arguments delimited by "`{{`" and "`}}`".

# Commands

## Options

Command and global options:

   Syntax         | Semantic 
------------------|--------------------------------
`--FLAG`          | Enable.
`--no-FLAG`       | Disable (false).
`--OPTION=VALUE`  | Sets option.
`--`              | Terminates all option parsing.

## Arguments

Most commands take one or more column arguments:

    Syntax              | Semantic
------------------------|--------------------------------
`COLUMN`                | Name or index.
`COLUMN:-`              | Reverse order or removal.
`COLUMN:+`              | Forward order or addition.
`COLUMN:!`              | Negation.
`COLUMN:arg1;arg2...`   | Processing arguments.
`COLUMN:opt1=val1;...`  | Processing options.

For most commands, all columns are processed when column arguments are given.

The column name  `"*"` implies all columns; see `cut` for examples.

# Global Options

  Syntax            | Semantic
--------------------|-------------------------
`--debug`           | Enable debugging info.
`--verbose`         | Enable verbose info.  
`--help`            | Print this document.    

# Example Data


```
 $ cat DUPLICATES.csv 
x,y,z
1,2,3
4,5,6
1,2,3
5,5,3

```


```
 $ cat EMOS.csv 
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
a,b,c,d

```


```
 $ cat HAS-UNUSED-COLUMNS.csv 
e,f,g,h
1,ab,,foo
24,,,bar
,5,,baz
,12,,abc

```


```
 $ cat OTHER.csv 
x,y
1,2
2,3
5,9

```


```
 $ cat SOME.csv 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc

```

# Commands

## `align`

Aligns fields based on column max_size and alignment.

Invocation: 

`align` 

Examples:

```
 $ cx in SOME.csv // -h // parse // align 
    1,ab   ,    3,foo  
   24,44   ,    6,bar  
  134,5    ,    9,baz  
    2,12   ,   11,abc  
```


## `cat`

Concatenates rows from multiple pipelines.  Columns are shared.

Invocation: 

`cat` 

Examples:

```
 $ cx in OTHER.csv // -h // cat {{ in DUPLICATES.csv // -h }} // h- 
x,y,z
1,2,
2,3,
5,9,
1,2,3
4,5,6
1,2,3
5,5,3
```


## `coerce`

Coerce columns by inferred types.

Invocation: 

`coerce` 

## `csv-in`

Parses CSV lines.

Aliases: `-csv`.

Invocation: 

`csv-in` 

## `csv-out`

Generates CSV lines.

Aliases: `csv-`.

Invocation: 

`csv-out` 

Examples:

```
 $ cx in SOME.csv // csv- --separator="\x09" 
a	b	c	d
1	ab	3	foo
24	44	6	bar
134	5	9	baz
2	12	11	abc
```


## `cut`

Cut columns.

Invocation: 

`cut` *column-args* *...* 

Examples:

```
 $ cx in SOME.csv // -h // cut a,d // h- 
a,d
1,foo
24,bar
134,baz
2,abc
```

```
 $ cx in SOME.csv // -h // cut b a c // h- 
b,a,c
ab,1,3
44,24,6
5,134,9
12,2,11
```

```
 $ cx in SOME.csv // -h // cut 'a,*' // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

```
 $ cx in SOME.csv // -h // cut 'd,*' // h- 
d,a,b,c
foo,1,ab,3
bar,24,44,6
baz,134,5,9
abc,2,12,11
```

```
 $ cx in SOME.csv // -h // cut '*,b:-' // h- 
a,c,d
1,3,foo
24,6,bar
134,9,baz
2,11,abc
```


## `delimited-in`

Parse delimited records.

Aliases: `-delimited`, `-d`.

Invocation: 

`delimited-in` *[* `--field-sep=...` `--record-sep=...` *]* 

Options:

* `--field-sep=...` - Default: ",".
* `--record-sep=...` - Default: system newline.

## `delimited-out`

Generate delimited records.

Aliases: `delimited-`, `d-`.

Invocation: 

`delimited-out` *column-args* *...* *[* `--field-sep=...` `--record-sep=...` `--multi-sep=...` *]* 

Options:

* `--field-sep=...` - Default: ",".
* `--record-sep=...` - Default: system newline.
* `--multi-sep=...` - Separator for enumerable values.  Default: ";".

## `empty-null`

Empty fields are converted to NULL.

Invocation: 

`empty-null` *column-args* *...* 

## `eval`

Evaluates Ruby code for each row.

Invocation: 

`eval` 

Examples:

```
 $ cx in SOME.csv // -h // parse // eval "row.map_vals!(&:class)" // h- 
a,b,c,d
Integer,String,Integer,String
Integer,Integer,Integer,String
Integer,Integer,Integer,String
Integer,Integer,Integer,String
```

```
 $ cx in SOME.csv // -h // parse // eval "self.a_to_power_of_c = a ** c" // h- 
a,b,c,d,a_to_power_of_c
1,ab,3,foo,1
24,44,6,bar,191102976
134,5,9,baz,13929745610903012864
2,12,11,abc,2048
```


## `grep`

Filters by regex.

Aliases: `g`.

Invocation: 

`grep` *column-args* *...* 

Examples:

```
 $ cx in SOME.csv // -h // grep d:f 
1,ab,3,foo
```

```
 $ cx in SOME.csv // -h // grep d:a 
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

```
 $ cx in SOME.csv // -h // grep d:^a 
2,12,11,abc
```

```
 $ cx in SOME.csv // -h // grep "d:!;f" 
24,44,6,bar
134,5,9,baz
2,12,11,abc
```


## `header-in`

Interprets first row as a column name header.

Aliases: `-header`, `-h`.

Invocation: 

`header-in` 

Examples:

```
 $ cx in SOME.csv // -csv // -h // csv- 
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```


## `header-out`

Emits column names as first row.

Aliases: `header-`, `h-`.

Invocation: 

`header-out` *[* `--meta-columns=...` *]* 

Options:

* `--meta-columns=...` - Emit each meta-column for each column.

Examples:

```
 $ cx in SOME.csv // -csv // -h // h- // csv- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```


## `help`

This documentation.

Invocation: 

`help` `command`

## `html-out`

Emits HTML.

Aliases: `html-`, `html`, `htm`.

Invocation: 

`html-out` *[* `--raw` `--filtering=...` `--title` `--table-only` `--indent=...` `--sorting=...` `--styled=...` `--head` `--body-head` `--body-foot` *]* 

Options:

* `--raw` - Comma-separated list of columns that contain raw HTML.
* `--filtering=...` - Enable filtering.  Default: true
* `--title` - Sets the HTML `title`.
* `--table-only` - Emit the HTML `table` only.
* `--indent=...` - Spaces to indent.  Default: 1
* `--sorting=...` - Enable sorting.  Default: true
* `--styled=...` - Enable styling.  Default: true
* `--head` - Additional raw HTML at foot of `head`.
* `--body-head` - Additional raw HTML at head of `body`.
* `--body-foot` - Additional raw HTML at foot of `body`.

## `io-in`

Read from a file.

Aliases: `-io`, `in`, `i`.

Invocation: 

`io-in` `filename` `...`

## `io-out`

Write records to a file.

Aliases: `io-`, `out`, `o`.

Invocation: 

`io-out` `filename` `...`

## `jira-out`

Generate a Jira table lines.

Aliases: `jira-`, `jira`.

Invocation: 

`jira-out` 

Examples:

```
 $ cx in SOME.csv // -h // jira 
||a||b||c||d||
|1|ab|3|foo|
|24|44|6|bar|
|134|5|9|baz|
|2|12|11|abc|
```


## `markdown-out`

Generate Markdown table lines.

Aliases: `markdown-`, `md`, `md-`, `markdown`.

Invocation: 

`markdown-out` *[* `--title=...` `--include-header=...` *]* 

Options:

* `--title=...` - Output title (caption).  Default: none.
* `--include-header=...` - Include a header.  Default: true.

Examples:

```
 $ cx in SOME.csv // -h // markdown 
| a     | b     | c     | d     |
| ----- | ----- | ----- | ----- |
| 1     | ab    | 3     | foo   |
| 24    | 44    | 6     | bar   |
| 134   | 5     | 9     | baz   |
| 2     | 12    | 11    | abc   |
```

```
 $ cx in SOME.csv // -h // parse // md 
| a     | b     | c     | d     |
| ----: | ----- | ----: | ----- |
|     1 | ab    |     3 | foo   |
|    24 | 44    |     6 | bar   |
|   134 | 5     |     9 | baz   |
|     2 | 12    |    11 | abc   |
```

```
 $ cx in SOME.csv // -h // parse // md --title=SOME.CSV 
| a     | b     | c     | d     |
| ----: | ----- | ----: | ----- |
|     1 | ab    |     3 | foo   |
|    24 | 44    |     6 | bar   |
|   134 | 5     |     9 | baz   |
|     2 | 12    |    11 | abc   |
[ SOME.CSV ]
```

```
 $ cx in SOME.csv // -h // parse // md --title=SOME.CSV --no-include-header 
|     1 | ab    |     3 | foo   |
|    24 | 44    |     6 | bar   |
|   134 | 5     |     9 | baz   |
|     2 | 12    |    11 | abc   |
[ SOME.CSV ]
```


## `meta-in`

Calculates various column metadata.

Aliases: `-meta`.

Invocation: 

`meta-in` 

Examples:

```
 $ cx in SOME.csv // -h // -meta // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```


## `meta-out`

Generate a table of column metadata.

Aliases: `meta-`.

Invocation: 

`meta-out` 

Examples:

```
 $ cx in SOME.csv // -h // -meta // meta- // h- 
name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred
a,a,true,0,0,,1,3,1,24,0,0,,,,String,
b,b,true,1,1,,1,2,12,ab,0,0,,,,String,
c,c,true,2,2,,1,2,11,9,0,0,,,,String,
d,d,true,3,3,,3,3,abc,foo,0,0,,,,String,
```

```
 $ cx in SOME.csv // -h // parse // -meta // meta- // h- 
name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred
a,a,true,0,0,Integer,1,3,1,134,0,0,,,,Integer,
b,b,true,1,1,Object,1,2,ab,ab,0,0,,,,String;Integer,
c,c,true,2,2,Integer,1,2,3,11,0,0,,,,Integer,
d,d,true,3,3,String,3,3,abc,foo,0,0,,,,String,
```


## `nop`

Does nothing -- output is same as input.

Aliases: `noop`.

Invocation: 

`nop` 

## `parse`

Parse strings into richer types.

Invocation: 

`parse` 

Examples:

```
 $ cx in SOME.csv // -h // parse // align // h- 
a,b,c,d
    1,ab   ,    3,foo  
   24,44   ,    6,bar  
  134,5    ,    9,baz  
    2,12   ,   11,abc  
```


## `quote`

Quote string values that would be ambigous or unprintable.

Aliases: `q`.

Invocation: 

`quote` *[* `--mode` `--strings-only` *]* 

Options:

* `--mode` - maybe, everything, always
* `--strings-only` - Ignore non-strings.

## `region`

Select a range of rows.

Aliases: `range`.

Invocation: 

`region` 

## `replace`

Replace by regex.

Aliases: `sub`.

Invocation: 

`replace` 

## `reverse`

Reverse order of rows.

Aliases: `tac`.

Invocation: 

`reverse` 

Examples:

```
 $ cx in SOME.csv // -h // reverse // h- 
a,b,c,d
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
```


## `row-id`

Inserts a row id column.

Invocation: 

`row-id` *[* `--name=...` `--type=...` `--start=...` *]* 

Options:

* `--name=...` - Name of id column.  Default: "__rowid__".
* `--type=...` - Type: "integer" or "uuid".  Default: "integer".
* `--start=...` - Start of integer ids.  Default: 1

Examples:

```
 $ cx in SOME.csv // -h // row-id --start=100 // h- 
__rowid__,a,b,c,d
100,1,ab,3,foo
101,24,44,6,bar
102,134,5,9,baz
103,2,12,11,abc
```

```
 $ cx in SOME.csv // -h // row-id --name=id // h- 
id,a,b,c,d
1,1,ab,3,foo
2,24,44,6,bar
3,134,5,9,baz
4,2,12,11,abc
```

```
 $ cx in SOME.csv // -h // row-id --type=uuid --name=uuid // h- 
uuid,a,b,c,d
4ce19f1a-a12f-0c89-0429-311871528c45,1,ab,3,foo
035fb7a3-1142-14a1-1a68-e5d97aeb3594,24,44,6,bar
292172a7-b6b9-6ed5-46bc-c9486137efdb,134,5,9,baz
40bf24bd-85f1-a061-752b-bcd099c8eceb,2,12,11,abc
```


## `set-meta`

Set column meta.

Invocation: 

`set-meta` 

Examples:

```
 $ cx in SOME.csv // -h // -meta // set-meta 'a:max_size=20;align=right' // md 
| a                    | b     | c     | d     |
| -------------------: | ----- | ----- | ----- |
|                    1 | ab    | 3     | foo   |
|                   24 | 44    | 6     | bar   |
|                  134 | 5     | 9     | baz   |
|                    2 | 12    | 11    | abc   |
```


## `sort`

Sorts by specified columns.

Aliases: `s`.

Invocation: 

`sort` 

Examples:

```
 $ cx in SOME.csv // -h // sort d  // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

```
 $ cx in SOME.csv // -h // sort    // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

```
 $ cx in SOME.csv // -h //            sort a    // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

```
 $ cx in SOME.csv // -h // parse   // sort a    // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

```
 $ cx in SOME.csv // -h // parse   // sort a:-  // h- 
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```


## `sql-out`

Generates CSV lines.

Aliases: `sql-`.

Invocation: 

`sql-out` *[* `--table` `--transaction` `--rollback` `--commit` `--create` `--temporary` `--insert` `--varchar-size=...` *]* 

Options:

* `--table` - Table name.
* `--transaction` - Emit a TRANSACTION block.
* `--rollback` - Emit a ROLLBACK statement.
* `--commit` - Emit a COMMIT statement.
* `--create` - Emit a CREATE TABLE statement.
* `--temporary` - CREATE TEMPORARY TABLE statement.
* `--insert` - Emit INSERT INTO statements.
* `--varchar-size=...` - VARCHAR(size). Default: 255.

Examples:

```
 $ cx in SOME.csv // -h // parse // sql- --table=SOME_TABLE --create 
CREATE TABLE SOME_TABLE
(
  a INT,
  b TEXT,
  c INT,
  d VARCHAR(255)
);

```

```
 $ cx in SOME.csv // -h // parse // sql- --table=SOME_TABLE --insert 
INSERT INTO SOME_TABLE
  (a, b, c, d)
VALUES
  (1, 'ab', 3, 'foo'),
  (24, 44, 6, 'bar'),
  (134, 5, 9, 'baz'),
  (2, 12, 11, 'abc');

```


## `strip`

Strip leading and trailing whitespace.

Aliases: `trim`.

Invocation: 

`strip` 

## `tee`

Send input to multiple output pipelines.

Aliases: `t`.

Invocation: 

`tee` `pipelines` `...`

## `transpose`

Transpose rows and columns.

Invocation: 

`transpose` *[* `--include-header=...` *]* 

Options:

* `--include-header=...` - Include header in first column.  Default: true

Examples:

```
 $ cx in SOME.csv // -h // transpose // h- 
_COL_1,_COL_2,_COL_3,_COL_4,_COL_5
a,1,24,134,2
b,ab,44,5,12
c,3,6,9,11
d,foo,bar,baz,abc
```

```
 $ cx in SOME.csv // -h // transpose --no-include-header // h- 
_COL_1,_COL_2,_COL_3,_COL_4
1,24,134,2
ab,44,5,12
3,6,9,11
foo,bar,baz,abc
```


## `type-inference`

Infer types from field strings.

Aliases: `-types`, `types`.

Invocation: 

`type-inference` 


# Installation

```
git clone https://github.com/kstephens/cx.git
gem install cx
```

# Attribution

Copyright 2020 - Kurt Stephens 

