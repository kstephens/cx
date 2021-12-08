# Overview

CX processes a pipeline of commands which transform tabular data.

A pipeline's commands are separated by "`//`" -- mnemonic: Unix shell pipe "`|`".

Some commands have pipelines arguments delimited by "`{{`" and "`}}`".

# Options

   Syntax           | Semantic 
--------------------|--------------------------------
`--FLAG`            | Enable.
`--no-FLAG`         | Disable (false).
`--OPTION=VALUE`    | Sets option.
`--`                | Terminates all option parsing.

# Arguments

Some commands take one or more column arguments:

    Syntax              | Semantic
------------------------|--------------------------------
`COLUMN`                | Name or index.
`COLUMN:-`              | Reverse order or removal.
`COLUMN:+`              | Forward order or addition.
`COLUMN:!`              | Negation.
`COLUMN:arg1;arg2...`   | Processing arguments.
`COLUMN:opt1=val1;...`  | Processing options.

For most commands, all columns are processed when column arguments are given.

The column name  `"*"` implies all columns.

# Global Options

  Syntax            | Semantic
--------------------|-------------------------
`--debug`           | Enable debugging info.
`--verbose`         | Enable verbose info.  
`--help`            | Print this document.    

# Example Data

See examples below for usage.

```
# DUPLICATES.csv
x,y,z
1,2,3
4,5,6
1,2,3
5,5,3

```

```
# EMOS.csv
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
a,b,c,d

```

```
# HAS-UNUSED-COLUMNS.csv
e,f,g,h
1,ab,,foo
24,,,bar
,5,,baz
,12,,abc

```

```
# OTHER.csv
x,y
1,2
2,3
5,9

```

```
# SOME.csv
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc

```

# Commands

## `align`

`align`

Aligns fields based on column max_size and alignment.

  Examples:

```
$ cx in SOME.csv // -h // parse // align
    1,ab   ,    3,foo  
   24,44   ,    6,bar  
  134,5    ,    9,baz  
    2,12   ,   11,abc  

```

## `cat`

`cat`

Concatenates rows from multiple pipelines.  Columns are shared.

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

`coerce`

Coerce columns by inferred types.

## `csv-in`

`csv-in`

Parses CSV lines.

Aliases: <span style='white-space: nowrap;>'<code>-csv</code></span>

## `csv-out`

`csv-out`

Generates CSV lines.

Aliases: <span style='white-space: nowrap;>'<code>csv-</code></span>

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

`cut`
*[* *column-args *...* *]*

Cut columns.

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

`delimited-in`
*[*
<span style='white-space: nowrap;>'<code>--field-sep=...</code></span>
<span style='white-space: nowrap;>'<code>--record-sep=...</code></span>*]*

Parse delimited records.

Aliases: <span style='white-space: nowrap;>'<code>-delimited</code></span>, <span style='white-space: nowrap;>'<code>-d</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--field-sep=...</code></span> | Default: ",".
<span style='white-space: nowrap;>'<code>--record-sep=...</code></span> | Default: system newline.

## `delimited-out`

`delimited-out`
*[*
<span style='white-space: nowrap;>'<code>--field-sep=...</code></span>
<span style='white-space: nowrap;>'<code>--record-sep=...</code></span>
<span style='white-space: nowrap;>'<code>--multi-sep=...</code></span>*]*
*[* *column-args *...* *]*

Generate delimited records.

Aliases: <span style='white-space: nowrap;>'<code>delimited-</code></span>, <span style='white-space: nowrap;>'<code>d-</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--field-sep=...</code></span> | Default: ",".
<span style='white-space: nowrap;>'<code>--record-sep=...</code></span> | Default: system newline.
<span style='white-space: nowrap;>'<code>--multi-sep=...</code></span> | Separator for enumerable values.  Default: ";".

## `empty-null`

`empty-null`
*[* *column-args *...* *]*

Empty fields are converted to NULL.

## `eval`

`eval`

Evaluates Ruby code for each row.

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

`grep`
*[* *column-args *...* *]*

Filters by regex.

Aliases: <span style='white-space: nowrap;>'<code>g</code></span>

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

`header-in`

Interprets first row as a column name header.

Aliases: <span style='white-space: nowrap;>'<code>-header</code></span>, <span style='white-space: nowrap;>'<code>-h</code></span>

  Examples:

```
$ cx in SOME.csv // -csv // -h // csv-
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc

```

## `header-out`

`header-out`
*[*
<span style='white-space: nowrap;>'<code>--meta-columns=...</code></span>*]*

Emits column names as first row.

Aliases: <span style='white-space: nowrap;>'<code>header-</code></span>, <span style='white-space: nowrap;>'<code>h-</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--meta-columns=...</code></span> | Emit a row for each meta-column containing the meta value for that column..

  Examples:

```
$ cx in SOME.csv // -csv // -h // h- // csv-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc

```

```
$ cx in SOME.csv // -csv // -h // parse // h- --meta-columns=type,max_value // csv-
__META__,a,b,c,d
type,Integer,Object,Integer,String
max_value,134,ab,11,foo
"",1,ab,3,foo
"",24,44,6,bar
"",134,5,9,baz
"",2,12,11,abc

```

## `help`

`help`
<span style='white-space: nowrap;>'<code>show</code></span>
<span style='white-space: nowrap;>'<code>run-examples</code></span>
<span style='white-space: nowrap;>'<code>make-help</code></span>

Show this documentation.

Subcommands:
* show         - this documentation (default).
* run-examples - runs all command examples into ex/cmd/.
* make-help    - regenerates this documetation.

## `html-out`

`html-out`
*[*
<span style='white-space: nowrap;>'<code>--raw</code></span>
<span style='white-space: nowrap;>'<code>--filtering=...</code></span>
<span style='white-space: nowrap;>'<code>--title</code></span>
<span style='white-space: nowrap;>'<code>--table-only</code></span>
<span style='white-space: nowrap;>'<code>--indent=...</code></span>
<span style='white-space: nowrap;>'<code>--sorting=...</code></span>
<span style='white-space: nowrap;>'<code>--styled=...</code></span>
<span style='white-space: nowrap;>'<code>--head</code></span>
<span style='white-space: nowrap;>'<code>--body-head</code></span>
<span style='white-space: nowrap;>'<code>--body-foot</code></span>*]*

Emits HTML.

Aliases: <span style='white-space: nowrap;>'<code>html-</code></span>, <span style='white-space: nowrap;>'<code>html</code></span>, <span style='white-space: nowrap;>'<code>htm</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--raw</code></span> | Comma-separated list of columns that contain raw HTML.
<span style='white-space: nowrap;>'<code>--filtering=...</code></span> | Enable filtering.  Default: true
<span style='white-space: nowrap;>'<code>--title</code></span> | Sets the HTML `title`.
<span style='white-space: nowrap;>'<code>--table-only</code></span> | Emit the HTML `table` only.
<span style='white-space: nowrap;>'<code>--indent=...</code></span> | Spaces to indent.  Default: 1
<span style='white-space: nowrap;>'<code>--sorting=...</code></span> | Enable sorting.  Default: true
<span style='white-space: nowrap;>'<code>--styled=...</code></span> | Enable styling.  Default: true
<span style='white-space: nowrap;>'<code>--head</code></span> | Additional raw HTML at foot of `head`.
<span style='white-space: nowrap;>'<code>--body-head</code></span> | Additional raw HTML at head of `body`.
<span style='white-space: nowrap;>'<code>--body-foot</code></span> | Additional raw HTML at foot of `body`.

## `io-in`

`io-in`
<span style='white-space: nowrap;>'<code>filename</code></span>
<span style='white-space: nowrap;>'<code>...</code></span>

Read from a file.

Aliases: <span style='white-space: nowrap;>'<code>-io</code></span>, <span style='white-space: nowrap;>'<code>in</code></span>, <span style='white-space: nowrap;>'<code>i</code></span>

## `io-out`

`io-out`
<span style='white-space: nowrap;>'<code>filename</code></span>
<span style='white-space: nowrap;>'<code>...</code></span>

Write records to a file.

Aliases: <span style='white-space: nowrap;>'<code>io-</code></span>, <span style='white-space: nowrap;>'<code>out</code></span>, <span style='white-space: nowrap;>'<code>o</code></span>

## `jira-out`

`jira-out`

Generate a Jira table lines.

Aliases: <span style='white-space: nowrap;>'<code>jira-</code></span>, <span style='white-space: nowrap;>'<code>jira</code></span>

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

`markdown-out`
*[*
<span style='white-space: nowrap;>'<code>--title=...</code></span>
<span style='white-space: nowrap;>'<code>--include-header=...</code></span>*]*

Generate Markdown table lines.

Aliases: <span style='white-space: nowrap;>'<code>markdown-</code></span>, <span style='white-space: nowrap;>'<code>md</code></span>, <span style='white-space: nowrap;>'<code>md-</code></span>, <span style='white-space: nowrap;>'<code>markdown</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--title=...</code></span> | Output title (caption).  Default: none.
<span style='white-space: nowrap;>'<code>--include-header=...</code></span> | Include a header.  Default: true.

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

`meta-in`

Calculates various column metadata.

Aliases: <span style='white-space: nowrap;>'<code>-meta</code></span>

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

`meta-out`

Generate a table of column metadata.

Aliases: <span style='white-space: nowrap;>'<code>meta-</code></span>

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

`nop`

Does nothing -- output is same as input.

Aliases: <span style='white-space: nowrap;>'<code>noop</code></span>

## `parse`

`parse`

Parse strings into richer types.

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

`quote`
*[*
<span style='white-space: nowrap;>'<code>--mode</code></span>
<span style='white-space: nowrap;>'<code>--strings-only</code></span>*]*

Quote string values that would be ambigous or unprintable.

Aliases: <span style='white-space: nowrap;>'<code>q</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--mode</code></span> | maybe, everything, always
<span style='white-space: nowrap;>'<code>--strings-only</code></span> | Ignore non-strings.

## `region`

`region`

Select a range of rows.

Aliases: <span style='white-space: nowrap;>'<code>range</code></span>

## `replace`

`replace`

Replace by regex.

Aliases: <span style='white-space: nowrap;>'<code>sub</code></span>

## `reverse`

`reverse`

Reverse order of rows.

Aliases: <span style='white-space: nowrap;>'<code>tac</code></span>

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

`row-id`
*[*
<span style='white-space: nowrap;>'<code>--name=...</code></span>
<span style='white-space: nowrap;>'<code>--type=...</code></span>
<span style='white-space: nowrap;>'<code>--start=...</code></span>*]*

Inserts a row id column.

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--name=...</code></span> | Name of id column.  Default: "__rowid__".
<span style='white-space: nowrap;>'<code>--type=...</code></span> | Type: "integer" or "uuid".  Default: "integer".
<span style='white-space: nowrap;>'<code>--start=...</code></span> | Start of integer ids.  Default: 1

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

`set-meta`

Set column meta.

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

```
$ cx in SOME.csv // -h // -meta // set-meta 'a:max_size=20;align=right;order=9' //  meta- // cut name,order,max_size,align // md
| name  | order | max_size | align |
| ----- | ----: | -------: | ----- |
| b     |     1 |        2 |       |
| c     |     2 |        2 |       |
| d     |     3 |        3 |       |
| a     |     9 |       20 | right |

```

```
$ cx in SOME.csv // -h // -meta // set-meta 'c:name=newname;order=-1' // md
| newname | a     | b     | d     |
| ------- | ----- | ----- | ----- |
| 3       | 1     | ab    | foo   |
| 6       | 24    | 44    | bar   |
| 9       | 134   | 5     | baz   |
| 11      | 2     | 12    | abc   |

```

## `sort`

`sort`

Sorts by specified columns.

Aliases: <span style='white-space: nowrap;>'<code>s</code></span>

  Examples:

```
$ cx in SOME.csv // -h // sort d  // h-
a,b,c,d
2,12,11,abc
24,44,6,bar
134,5,9,baz
1,ab,3,foo

```

```
$ cx in SOME.csv // -h // sort    // h-
a,b,c,d
1,ab,3,foo
134,5,9,baz
2,12,11,abc
24,44,6,bar

```

```
$ cx in SOME.csv // -h //            sort a    // h-
a,b,c,d
1,ab,3,foo
134,5,9,baz
2,12,11,abc
24,44,6,bar

```

```
$ cx in SOME.csv // -h // parse   // sort a    // h-
a,b,c,d
1,ab,3,foo
2,12,11,abc
24,44,6,bar
134,5,9,baz

```

```
$ cx in SOME.csv // -h // parse   // sort a:-  // h-
a,b,c,d
134,5,9,baz
24,44,6,bar
2,12,11,abc
1,ab,3,foo

```

## `sql-out`

`sql-out`
*[*
<span style='white-space: nowrap;>'<code>--table</code></span>
<span style='white-space: nowrap;>'<code>--transaction</code></span>
<span style='white-space: nowrap;>'<code>--rollback</code></span>
<span style='white-space: nowrap;>'<code>--commit</code></span>
<span style='white-space: nowrap;>'<code>--create</code></span>
<span style='white-space: nowrap;>'<code>--temporary</code></span>
<span style='white-space: nowrap;>'<code>--insert</code></span>
<span style='white-space: nowrap;>'<code>--varchar-size=...</code></span>*]*

Generates CSV lines.

Aliases: <span style='white-space: nowrap;>'<code>sql-</code></span>

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--table</code></span> | Table name.
<span style='white-space: nowrap;>'<code>--transaction</code></span> | Emit a TRANSACTION block.
<span style='white-space: nowrap;>'<code>--rollback</code></span> | Emit a ROLLBACK statement.
<span style='white-space: nowrap;>'<code>--commit</code></span> | Emit a COMMIT statement.
<span style='white-space: nowrap;>'<code>--create</code></span> | Emit a CREATE TABLE statement.
<span style='white-space: nowrap;>'<code>--temporary</code></span> | CREATE TEMPORARY TABLE statement.
<span style='white-space: nowrap;>'<code>--insert</code></span> | Emit INSERT INTO statements.
<span style='white-space: nowrap;>'<code>--varchar-size=...</code></span> | VARCHAR(size). Default: 255.

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

`strip`

Strip leading and trailing whitespace.

Aliases: <span style='white-space: nowrap;>'<code>trim</code></span>

## `tee`

`tee`
<span style='white-space: nowrap;>'<code>pipelines</code></span>
<span style='white-space: nowrap;>'<code>...</code></span>

Send input to multiple output pipelines.

Aliases: <span style='white-space: nowrap;>'<code>t</code></span>

## `transpose`

`transpose`
*[*
<span style='white-space: nowrap;>'<code>--include-header=...</code></span>*]*

Transpose rows and columns.

  Options                   |  Description
----------------------------|-------------------------------
<span style='white-space: nowrap;>'<code>--include-header=...</code></span> | Include header in first column.  Default: true

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

`type-inference`

Infer types from field strings.

Aliases: <span style='white-space: nowrap;>'<code>-types</code></span>, <span style='white-space: nowrap;>'<code>types</code></span>


