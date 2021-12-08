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

Aliases: -csv

## `csv-out`

`csv-out`

Generates CSV lines.

Aliases: csv-

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
--field-sep=...
--record-sep=... *]*

Parse delimited records.

Aliases: -delimited, -d

  Options                   |  Description
----------------------------|-------------------------------
--field-sep=... | Default: ",".
--record-sep=... | Default: system newline.

## `delimited-out`

`delimited-out`
 *[*
--field-sep=...
--record-sep=...
--multi-sep=... *]*
*[* *column-args *...* *]*

Generate delimited records.

Aliases: delimited-, d-

  Options                   |  Description
----------------------------|-------------------------------
--field-sep=... | Default: ",".
--record-sep=... | Default: system newline.
--multi-sep=... | Separator for enumerable values.  Default: ";".

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

Aliases: g

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

Aliases: -header, -h

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
--meta-columns=... *]*

Emits column names as first row.

Aliases: header-, h-

  Options                   |  Description
----------------------------|-------------------------------
--meta-columns=... | Emit a row for each meta-column containing the meta value for that column..

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
show
run-examples
make-help

Show this documentation.

Subcommands:
* show         - this documentation (default).
* run-examples - runs all command examples into ex/cmd/.
* make-help    - regenerates this documetation.

## `html-out`

`html-out`
 *[*
--raw
--filtering=...
--title
--table-only
--indent=...
--sorting=...
--styled=...
--head
--body-head
--body-foot *]*

Emits HTML.

Aliases: html-, html, htm

  Options                   |  Description
----------------------------|-------------------------------
--raw | Comma-separated list of columns that contain raw HTML.
--filtering=... | Enable filtering.  Default: true
--title | Sets the HTML `title`.
--table-only | Emit the HTML `table` only.
--indent=... | Spaces to indent.  Default: 1
--sorting=... | Enable sorting.  Default: true
--styled=... | Enable styling.  Default: true
--head | Additional raw HTML at foot of `head`.
--body-head | Additional raw HTML at head of `body`.
--body-foot | Additional raw HTML at foot of `body`.

## `io-in`

`io-in`
filename
...

Read from a file.

Aliases: -io, in, i

## `io-out`

`io-out`
filename
...

Write records to a file.

Aliases: io-, out, o

## `jira-out`

`jira-out`

Generate a Jira table lines.

Aliases: jira-, jira

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
--title=...
--include-header=... *]*

Generate Markdown table lines.

Aliases: markdown-, md, md-, markdown

  Options                   |  Description
----------------------------|-------------------------------
--title=... | Output title (caption).  Default: none.
--include-header=... | Include a header.  Default: true.

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

Aliases: -meta

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

Aliases: meta-

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

Aliases: noop

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
--mode
--strings-only *]*

Quote string values that would be ambigous or unprintable.

Aliases: q

  Options                   |  Description
----------------------------|-------------------------------
--mode | maybe, everything, always
--strings-only | Ignore non-strings.

## `region`

`region`

Select a range of rows.

Aliases: range

  Examples:

```
$ cx in RANDOM.csv // -h // region -1            // h-
id,a,b,c,X %
1100,-27,ylb ,39.6,39%
```

```
$ cx in RANDOM.csv // -h // region 2,4,6         // h-
id,a,b,c,X %
1002,77,ymt,0.4,48%
1004,-62,rcz ,1.2,127%
1006,67,hjn,"",187%
```

```
$ cx in RANDOM.csv // -h // region 11..14        // h-
id,a,b,c,X %
1011,39,axr,"",97%
1012,-38,wky,4.4,60%
1013,73,dmm ,4.8,197%
1014,48,gys,5.2,49%
```

```
$ cx in RANDOM.csv // -h // region 11...14       // h-
id,a,b,c,X %
1011,39,axr,"",97%
1012,-38,wky,4.4,60%
1013,73,dmm ,4.8,197%
```

```
$ cx in RANDOM.csv // -h // region 9..1          // h-
id,a,b,c,X %
1009,-99,ali,3.2,191%
1008,-21,qeg,2.8,135%
1007,-72,xgv ,2.4,55%
1006,67,hjn,"",187%
1005,-38,oub,1.6,9%
1004,-62,rcz ,1.2,127%
1003,84,yis,0.8,12%
1002,77,ymt,0.4,48%
1001,79,ekl ,"",133%
```

```
$ cx in RANDOM.csv // -h // region -9..-1        // h-
id,a,b,c,X %
1092,-74,rjz,36.4,76%
1093,-51,fzi,36.8,193%
1094,-27,okd ,37.2,21%
1095,87,azt,37.6,57%
1096,-9,ywj,"",127%
1097,-88,jte ,38.4,170%
1098,56,gns,38.8,64%
1099,-4,sod,39.2,151%
1100,-27,ylb ,39.6,39%
```

```
$ cx in RANDOM.csv // -h // region 2,4,10..15    // h-
id,a,b,c,X %
1002,77,ymt,0.4,48%
1004,-62,rcz ,1.2,127%
1010,-71,jtj ,3.6,25%
1011,39,axr,"",97%
1012,-38,wky,4.4,60%
1013,73,dmm ,4.8,197%
1014,48,gys,5.2,49%
1015,-92,ndu,5.6,80%
```

## `replace`

`replace`
 *[*
--search=
--replace=
--global *]*

Replace by regex.

Aliases: sub

  Options                   |  Description
----------------------------|-------------------------------
--search= | Search for in all columns.
--replace= | Replace matches with.
--global | Replace all occurances.

  Examples:

```
$ cx in RANDOM.csv // -h // region 1..5 // replace "x_:%;" // h-
id,a,b,c,X %
1001,79,ekl ,"",133
1002,77,ymt,0.4,48
1003,84,yis,0.8,12
1004,-62,rcz ,1.2,127
1005,-38,oub,1.6,9
```

```
$ cx in RANDOM.csv // -h // region 1..5 // replace --search=1 --replace=_ // h-
id,a,b,c,X %
_001,79,ekl ,"",_33%
_002,77,ymt,0.4,48%
_003,84,yis,0.8,_2%
_004,-62,rcz ,_.2,_27%
_005,-38,oub,_.6,9%
```

```
$ cx in RANDOM.csv // -h // region 1..5 // replace --search=1 --replace= --global // h-
id,a,b,c,X %
00,79,ekl ,"",33%
002,77,ymt,0.4,48%
003,84,yis,0.8,2%
004,-62,rcz ,.2,27%
005,-38,oub,.6,9%
```

## `reverse`

`reverse`

Reverse order of rows.

Aliases: tac

  Examples:

```
$ cx in SOME.csv // -h // reverse // h-
a,b,c,d
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
```

```
$ cx in SOME.csv // reverse
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
a,b,c,d
```

## `row-id`

`row-id`
 *[*
--name=...
--type=...
--start=... *]*

Inserts a row id column.

  Options                   |  Description
----------------------------|-------------------------------
--name=... | Name of id column.  Default: "__rowid__".
--type=... | Type: "integer" or "uuid".  Default: "integer".
--start=... | Start of integer ids.  Default: 1

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

Aliases: s

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
--table
--transaction
--rollback
--commit
--create
--temporary
--insert
--varchar-size=... *]*

Generates CSV lines.

Aliases: sql-

  Options                   |  Description
----------------------------|-------------------------------
--table | Table name.
--transaction | Emit a TRANSACTION block.
--rollback | Emit a ROLLBACK statement.
--commit | Emit a COMMIT statement.
--create | Emit a CREATE TABLE statement.
--temporary | CREATE TEMPORARY TABLE statement.
--insert | Emit INSERT INTO statements.
--varchar-size=... | VARCHAR(size). Default: 255.

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

Aliases: trim

## `tee`

`tee`
pipelines
...

Send input to multiple output pipelines.

Aliases: t

## `transpose`

`transpose`
 *[*
--include-header=... *]*

Transpose rows and columns.

  Options                   |  Description
----------------------------|-------------------------------
--include-header=... | Include header in first column.  Default: true

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

Aliases: -types, types

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
# RANDOM.csv
id,a,b,c,X %
1001,79,ekl ,"",133%
1002,77,ymt,0.4,48%
1003,84,yis,0.8,12%
1004,-62,rcz ,1.2,127%
1005,-38,oub,1.6,9%
1006,67,hjn,"",187%
1007,-72,xgv ,2.4,55%
1008,-21,qeg,2.8,135%
1009,-99,ali,3.2,191%
1010,-71,jtj ,3.6,25%
1011,39,axr,"",97%
1012,-38,wky,4.4,60%
1013,73,dmm ,4.8,197%
1014,48,gys,5.2,49%
1015,-92,ndu,5.6,80%
1016,-44,ndr ,"",26%
1017,-71,ewo,6.4,173%
1018,26,cwc,6.8,186%
1019,-72,cag ,7.2,50%
1020,51,iws,7.6,145%
1021,18,ypl,"",143%
1022,29,jer ,8.4,184%
1023,-82,pmc,8.8,63%
1024,-71,ohv,9.2,185%
1025,-11,dut ,9.6,98%
1026,-69,zwq,"",124%
1027,-47,znc,10.4,200%
1028,-4,ngr ,10.8,38%
1029,16,ynb,11.2,58%
1030,-52,mwc,11.6,89%
1031,-49,qcg ,"",169%
1032,-57,man,12.4,150%
1033,15,pyz,12.8,51%
1034,73,qhh ,13.2,58%
1035,-5,brj,13.6,72%
1036,2,mec,"",95%
1037,-63,dnp ,14.4,101%
1038,-28,xxj,14.8,66%
1039,-63,ggv,15.2,83%
1040,84,nit ,15.6,13%
1041,57,gwh,"",108%
1042,-25,cop,16.4,81%
1043,-19,jgi ,16.8,68%
1044,89,qji,17.2,148%
1045,-7,ypx,17.6,64%
1046,-96,lak ,"",13%
1047,-96,kfb,18.4,133%
1048,-7,dac,18.8,54%
1049,-59,kmf ,19.2,194%
1050,2,mwf,19.6,192%
1051,5,kkm,"",138%
1052,-51,fqv ,20.4,7%
1053,8,rli,20.8,68%
1054,14,yno,21.2,81%
1055,1,yzl ,21.6,101%
1056,0,hst,"",183%
1057,56,ydn,22.4,88%
1058,57,eyd ,22.8,7%
1059,63,kyc,23.2,1%
1060,79,yaq,23.6,124%
1061,28,njo ,"",182%
1062,16,xxz,24.4,36%
1063,60,hxh,24.8,15%
1064,-81,dwn ,25.2,103%
1065,-48,jvf,25.6,146%
1066,-37,emd,"",140%
1067,-2,prq ,26.4,186%
1068,-56,unw,26.8,134%
1069,95,qkc,27.2,47%
1070,9,pcx ,27.6,45%
1071,53,odm,"",128%
1072,-99,kty,28.4,166%
1073,-15,rvs ,28.8,54%
1074,-76,wgq,29.2,43%
1075,-100,gwp,29.6,87%
1076,23,mfa ,"",173%
1077,-80,fin,30.4,161%
1078,-53,ner,30.8,29%
1079,-64,yde ,31.2,94%
1080,-63,gzh,31.6,188%
1081,44,mhj,"",124%
1082,-29,qce ,32.4,20%
1083,95,kbs,32.8,156%
1084,9,igk,33.2,119%
1085,-70,pwi ,33.6,38%
1086,6,ukh,"",119%
1087,-24,qdc,34.4,101%
1088,-68,rzb ,34.8,142%
1089,-72,zqw,35.2,73%
1090,41,lzz,35.6,112%
1091,17,nvh ,"",79%
1092,-74,rjz,36.4,76%
1093,-51,fzi,36.8,193%
1094,-27,okd ,37.2,21%
1095,87,azt,37.6,57%
1096,-9,ywj,"",127%
1097,-88,jte ,38.4,170%
1098,56,gns,38.8,64%
1099,-4,sod,39.2,151%
1100,-27,ylb ,39.6,39%
```

```
# SOME.csv
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

# Attribution

Copyright 2020 - Kurt Stephens 


