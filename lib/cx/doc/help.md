# Overview

CX transforms tabular data through a pipeline of commands.

Pipeline commands are separated by "`//`" -- mnemonic: Unix shell pipe "`|`".

Some commands have subpipelines arguments delimited by "`{{`" and "`}}`".

# Installation

```
# Install ruby 2.7.1+
$ rbenv install 2.7.1
$ rbenv shell 2.7.1
$ git clone https://github.com/kstephens/cx.git
$ cd cx
$ npm install -g minify
$ bundle exec rake install
```

# Options

Syntax              | Semantic                           |
--------------------|------------------------------------|
`--FLAG`            | Enable.                            |
`--no-FLAG`         | Disable (false).                   |
`--OPTION=VALUE`    | Sets option.                       |
`--`                | Terminates all option parsing.     |

# Column Arguments

Some commands take one or more column arguments:

Syntax                  | Semantic                       |
------------------------|--------------------------------|
`COLUMN`                | Column name or index number.   |
`COLUMN:-`              | Reverse order or removal.      |
`COLUMN:+`              | Forward order or addition.     |
`COLUMN:!`              | Negation.                      |
`COLUMN:arg1;arg2...`   | Processing arguments.          |
`COLUMN:opt1=val1;...`  | Processing options.            |

A `COLUMN` can be a name or an index number.

Index numbers are non-zero.  Positive values are 1-origin: e.g. `2` is the second column, `-2` is the second to the last column.

For most commands, all columns are processed when column arguments are given.

The column name  `"*"` implies all columns.

See the `cut`, `grep`, `sort` and `uniq` commands for examples.

# Global Options

  Syntax            | Semantic                |
--------------------|-------------------------|
`--debug`           | Enable debugging info.  |
`--verbose`         | Enable verbose info.    |
`--help`            | Print this document.    |

# Commands

 Command        | Synopsis                                                        | Aliases                   |
----------------|-----------------------------------------------------------------|---------------------------|
 align          | Aligns fields based on column max_size and alignment.           |                           |
 cat            | Concatenates rows from multiple pipelines.  Columns are shared. |                           |
 cmd            | Pipe through an external command.                               | command /                 |
 coerce         | Coerce columns by inferred types.                               |                           |
 csv-in         | Parses CSV lines.                                               | -csv                      |
 csv-out        | Generates CSV lines.                                            | csv-                      |
 cut            | Cut columns.                                                    |                           |
 delimited-in   | Parse delimited records.                                        | -delimited -d             |
 delimited-out  | Generate delimited records.                                     | delimited- d-             |
 edn-in         | Parses EDN.                                                     | -edn                      |
 edn-out        | Emits EDN.                                                      | edn-                      |
 empty-null     | Empty fields are converted to NULL.                             |                           |
 erb-out        | Evaluates ERB in the context of input table.                    | erb- erb                  |
 eval           | Evaluates Ruby code for each row.                               |                           |
 gnuplot-out    | Generate GNUPLOT file.                                          | gnuplot- gnuplot          |
 grep           | Filters by regex.                                               | g                         |
 header-in      | Interprets first row as a column name header.                   | -header -h                |
 header-out     | Emits column names as first row.                                | header- h-                |
 help           | Show this documentation.                                        |                           |
 html-out       | Emits HTML.                                                     | html- html htm            |
 io-in          | Read from a file.                                               | -io in i                  |
 io-out         | Write records to a file.                                        | io- out o                 |
 jira-out       | Generate a Jira table lines.                                    | jira- jira                |
 json-in        | Parses JSON.                                                    | -json                     |
 json-out       | Emits JSON.                                                     | json-                     |
 markdown-in    | Parse Markdown. (PoC)                                           | -markdown -md             |
 markdown-out   | Generate Markdown table lines.                                  | markdown- md md- markdown |
 meta-in        | Calculates various column metadata.                             | -meta                     |
 meta-out       | Generate a table of column metadata.                            | meta-                     |
 meta-set       | Set column meta.                                                | meta= set-meta            |
 nop            | Does nothing -- output is same as input.                        | noop                      |
 parse          | Parse strings into richer types.                                |                           |
 quote          | Quote string values that would be ambigous or unprintable.      | q                         |
 record-in      | Parses records.                                                 | -record                   |
 record-out     | Generates records.                                              | record-                   |
 region         | Select a range of rows.                                         | range                     |
 reject         | Reject rows for Ruby expressions that evaluation true.          |                           |
 remove-empty   | Empty columns and rows are removed.                             | compact                   |
 replace        | Replace by regex.                                               | sub                       |
 reverse        | Reverse order of rows.                                          | tac                       |
 row-id         | Inserts a row id column.                                        |                           |
 select         | Select rows for Ruby expressions that evaluation true.          |                           |
 sort           | Sorts by specified columns.                                     | s                         |
 sql-out        | Generate SQL.                                                   | sql-                      |
 stats          | Collect stats of a group of columns.                            |                           |
 strip          | Strip leading and trailing whitespace.                          | trim                      |
 tee            | Send input to multiple output pipelines.                        | t                         |
 transpose      | Transpose rows and columns.                                     |                           |
 tsv-in         | Parses TSV lines.                                               | -tsv                      |
 tsv-out        | Generates TSV lines.                                            | tsv-                      |
 type-inference | Infer types from field strings.                                 | -types types              |
 uniq           | Emit only rows with uniq columns.                               |                           |

# Command Detail

## `align`

`align` *[* *column-args ...* *]* 
Synopsis: Aligns fields based on column max_size and alignment.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // align
    1,ab   ,    3,foo  
   24,44   ,    6,bar  
  134,5    ,    9,baz  
    2,12   ,   11,abc  
```

-------------------------------------

-------------------------------------

-------------------------------------
## `cat`

`cat` 
Synopsis: Concatenates rows from multiple pipelines.  Columns are shared.

  Examples:

-------------------------------------

```none
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

-------------------------------------

-------------------------------------

-------------------------------------
## `cmd`

`cmd` `command` `args...` 
Synopsis: Pipe through an external command.

Aliases: `command`, `/`

-------------------------------------
## `coerce`

`coerce` *[* *column-args ...* *]* 
Synopsis: Coerce columns by inferred types.

-------------------------------------
## `csv-in`

`csv-in`  *[* `--separator=...`  *]* 
Synopsis: Parses CSV lines.

Aliases: `-csv`

 Options           | Description                          | Default | Values |
-------------------|--------------------------------------|---------|--------|
 `--separator=...` | Column separator: defaults to `","`. |         |        |

-------------------------------------
## `csv-out`

`csv-out`  *[* `--separator=...`  *]* 
Synopsis: Generates CSV lines.

Aliases: `csv-`

 Options           | Description                          | Default | Values |
-------------------|--------------------------------------|---------|--------|
 `--separator=...` | Column separator: defaults to `","`. |         |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // csv- --separator="\x09"
a	b	c	d
1	ab	3	foo
24	44	6	bar
134	5	9	baz
2	12	11	abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `cut`

`cut` *[* *column-args ...* *]* 
Synopsis: Cut columns.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // cut a,d // h-
a,d
1,foo
24,bar
134,baz
2,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut b a c // h-
b,a,c
ab,1,3
44,24,6
5,134,9
12,2,11
```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut 'a,*' // h-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut 'd,*' // h-
d,a,b,c
foo,1,ab,3
bar,24,44,6
baz,134,5,9
abc,2,12,11
```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut '*,b:-' // h-
a,c,d
1,3,foo
24,6,bar
134,9,baz
2,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut 2,1 // h-
b,a
ab,1
44,24
5,134
12,2
```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut -1,-2 // h-
d,c
foo,3
bar,6
baz,9
abc,11
```

-------------------------------------

-------------------------------------

-------------------------------------
## `delimited-in`

`delimited-in`  *[* `--field-sep=...` `--record-sep=...`  *]* 
Synopsis: Parse delimited records.

Aliases: `-delimited`, `-d`

 Options            | Description | Default        | Values |
--------------------|-------------|----------------|--------|
 `--field-sep=...`  |             | ","            |        |
 `--record-sep=...` |             | system newline |        |

-------------------------------------
## `delimited-out`

`delimited-out`  *[* `--field-sep=...` `--record-sep=...` `--multi-sep=...`  *]* *[* *column-args ...* *]* 
Synopsis: Generate delimited records.

Aliases: `delimited-`, `d-`

 Options            | Description                      | Default        | Values |
--------------------|----------------------------------|----------------|--------|
 `--field-sep=...`  |                                  | ","            |        |
 `--record-sep=...` |                                  | system newline |        |
 `--multi-sep=...`  | Separator for enumerable values. | ";"            |        |

-------------------------------------
## `edn-in`

`edn-in` 
Synopsis: Parses EDN.

Aliases: `-edn`

  Examples:

-------------------------------------

```none
$ cx in SOME.edn // -edn // h-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `edn-out`

`edn-out` 
Synopsis: Emits EDN.

Aliases: `edn-`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // edn-
[
{:a 1 :b "ab" :c 3 :d "foo"}
{:a 24 :b 44 :c 6 :d "bar"}
{:a 134 :b 5 :c 9 :d "baz"}
{:a 2 :b 12 :c 11 :d "abc"}
]
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // h- // edn- --mode=row
[
["a" "b" "c" "d"]
[1 "ab" 3 "foo"]
[24 44 6 "bar"]
[134 5 9 "baz"]
[2 12 11 "abc"]
]
```

-------------------------------------

-------------------------------------

-------------------------------------
## `empty-null`

`empty-null` *[* *column-args ...* *]* 
Synopsis: Empty fields are converted to NULL.

-------------------------------------
## `erb-out`

`erb-out`  *[* `--erb-options=...`  *]* `template.erb` 
Synopsis: Evaluates ERB in the context of input table.

Aliases: `erb-`, `erb`

 Options             | Description            | Default | Values |
---------------------|------------------------|---------|--------|
 `--erb-options=...` | See ERB doc trim_mode. |         |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -csv // -h // erb SOME.erb
=== HEADER ===
columns = a, b, c, d
size    = 4

  Row 0 : 1, ab, 3, foo
  Row 1 : 24, 44, 6, bar
  Row 2 : 134, 5, 9, baz
  Row 3 : 2, 12, 11, abc
=== FOOTER ===

```

-------------------------------------

-------------------------------------

-------------------------------------
## `eval`

`eval` 
Synopsis: Evaluates Ruby code for each row.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // eval "row.map_vals!(&:class)" // h-
a,b,c,d
Integer,String,Integer,String
Integer,Integer,Integer,String
Integer,Integer,Integer,String
Integer,Integer,Integer,String
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // eval "self.a_to_power_of_c = a ** c" // h-
a,b,c,d,a_to_power_of_c
1,ab,3,foo,1
24,44,6,bar,191102976
134,5,9,baz,13929745610903012864
2,12,11,abc,2048
```

-------------------------------------

-------------------------------------

-------------------------------------
## `gnuplot-out`

`gnuplot-out`  *[* `--style=...` `--color` `--format=...` `--title=...` `--size=...` `--xrange=...` `--yrange=...` `--boxwidth=...` `--x-labels`  *]* *[* *column-args ...* *]* 
Synopsis: Generate GNUPLOT file.

Aliases: `gnuplot-`, `gnuplot`

 Options          | Description                                                | Default | Values |
------------------|------------------------------------------------------------|---------|--------|
 `--style=...`    | Style of chart.  Values: "plot", "barchart", "statistics". | "plot"  |        |
 `--color`        | Generate color plot.                                       | false   |        |
 `--format=...`   | Gnuplot format: term,tty,console,svg,...                   |         |        |
 `--title=...`    | Title.                                                     | none    |        |
 `--size=...`     | width x height.  Default TTY size or 1024x768.             |         |        |
 `--xrange=...`   | min:max.                                                   | auto    |        |
 `--yrange=...`   | min:max.                                                   | auto    |        |
 `--boxwidth=...` |                                                            | 0.75    |        |
 `--x-labels`     | the X column contains discrete labels.                     |         |        |

  Examples:

-------------------------------------

```none
$ cx in plot.csv // -h // gnuplot- --size=80x25 // cmd gnuplot
                                                                                
                                                                                
                                      plot.csv                                  
     160 +                                                                      
                                                                    ##W         
     140 +                                                     ##### **V***     
                                                         ###W##   y2 ##W###     
     120 +                                         ###W##                       
         V****                               ######                             
     100 +    ***V**                   ######                                   
                 *  *****        ######                                         
      80 +        *      ***#W#W#                                               
                  *  ####### **V                                                
      60 +      #W##W          *                                                
            ####   *          *                                                 
      40 W##       *          *                      *******V                   
                   *         *       ****************      *                    
      20 +          *        V*******                    **         **V         
                    V                                   *      *****            
       0 +                                             * ******                 
                                                      V**                       
     -20 +          +          +           +          +          +          +   
         40         60         80         100        120        140        160  
                                          x                                     
                                                                                
```

-------------------------------------

```none
$ cx in plot.csv // -h // gnuplot- --size=80x25 x // cmd gnuplot
                                                                                
                                                                                
                                      plot.csv                                  
     100 +                                                                  V   
                                                                           *    
      90 +                                                         x **V***     
                                                                         *      
      80 +                                                              *       
                                                                       *        
      70 +                                                            *         
                                                                   **V          
      60 +                                                     ****             
      50 +                                            V******V*                 
                                                    **                          
      40 +                                        **                            
                                                 *                              
      30 +                                     **                               
                                           ***V                                 
      20 +                            *V***                                     
                                   ***                                          
      10 +                       **                                             
                    ****V******V*                                               
       0 V******V***    +      +       +      +       +      +       +      +   
         0      1       2      3       4      5       6      7       8      9   
                                                                                
```

-------------------------------------

```none
$ cx in plot.csv // -h // gnuplot- --size=80x25 x y2 // cmd gnuplot
```

-------------------------------------

```none
$ cx in plot.csv // -h // gnuplot- --size=80x25 --style=b x // cmd gnuplot
                                                                                
                                                                                
                                      plot.csv                                  
     100 +  +             +            +             +            +  ********   
            +             +            +             +            +  *      *   
      90 +                                                         x ****** *   
                                                                     *      *   
      80 +                                                           *      *   
                                                                     *      *   
      70 +                                                           *      *   
                                                               *******      *   
      60 +                                                     *     *      *   
      50 +                                       ***************     *      *   
                                                 *      *      *     *      *   
      40 +                                       *      *      *     *      *   
                                                 *      *      *     *      *   
      30 +                                       *      *      *     *      *   
                                           *******      *      *     *      *   
      20 +                          ********     *      *      *     *      *   
                                    *      *     *      *      *     *      *   
      10 +                          *      *     *      *      *     *      *   
            +         ***************  +   *     *   +  *      *  +  *      *   
       0 ********************************************************************   
            0             2            4             6            8             
                                                                                
```

-------------------------------------

-------------------------------------

-------------------------------------
## `grep`

`grep`  *[* `--negate`  *]* *[* *column-args ...* *]* 
Synopsis: Filters by regex.

Aliases: `g`

 Options    | Description                 | Default | Values |
------------|-----------------------------|---------|--------|
 `--negate` | Negate match. Alias: `--v`. |         |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // grep d:f
1,ab,3,foo
```

-------------------------------------

```none
$ cx in SOME.csv // -h // grep d:a
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // grep d:^a
2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // grep "d:!;f"
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `header-in`

`header-in` 
Synopsis: Interprets first row as a column name header.

Aliases: `-header`, `-h`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -csv // -h // csv-
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `header-out`

`header-out`  *[* `--meta-columns=...`  *]* 
Synopsis: Emits column names as first row.

Aliases: `header-`, `h-`

 Options              | Description                                                                 | Default | Values           |
----------------------|-----------------------------------------------------------------------------|---------|------------------|
 `--meta-columns=...` | Emit a row for each meta-column containing the meta value for that column.. |         | meta-column, ... |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -csv // -h // h- // csv-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -csv // -h // parse // h- --meta-columns=type,max_value // csv-
__META__,a,b,c,d
type,Integer,Object,Integer,String
max_value,134,ab,11,foo
"",1,ab,3,foo
"",24,44,6,bar
"",134,5,9,baz
"",2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `help`

`help` `run-examples!` `make-help!` 
Synopsis: Show this documentation.

Subcommands:
* run-examples! - runs all command examples into ex/cmd/.
* make-help!    - regenerates this documetation.
-------------------------------------
## `html-out`

`html-out`  *[* `--title=...` `--table-only` `--filtering` `--sorting` `--styled` `--filtering-tooltip` `--raw=...` `--link=...` `--head=...` `--body-head=...` `--body-foot=...` `--indent=...`  *]* *[* *column-args ...* *]* 
Synopsis: Emits HTML.

Aliases: `html-`, `html`, `htm`

 Options               | Description                                          | Default | Values |
-----------------------|------------------------------------------------------|---------|--------|
 `--title=...`         | Sets the HTML `title`.                               |         |        |
 `--table-only`        | Emit the HTML `table` only.                          |         |        |
 `--filtering`         | Enable filtering.                                    | `true`  |        |
 `--sorting`           | Enable sorting.                                      | `true`  |        |
 `--styled`            | Enable styling.                                      | `true`  |        |
 `--filtering-tooltip` | Enable filtering tooltip.                            | `true`  |        |
 `--raw=...`           | Comma-separated list of columns containing raw HTML. |         |        |
 `--link=...`          | Comma-separated list of columns containing URLS.     |         |        |
 `--head=...`          | Additional raw HTML at foot of `head`.               |         |        |
 `--body-head=...`     | Additional raw HTML at head of `body`.               |         |        |
 `--body-foot=...`     | Additional raw HTML at foot of `body`.               |         |        |
 `--indent=...`        | Spaces to indent.                                    | `1`     |        |

-------------------------------------
## `io-in`

`io-in` `filename` `...` 
Synopsis: Read from a file.

Aliases: `-io`, `in`, `i`

-------------------------------------
## `io-out`

`io-out` `filename` `...` 
Synopsis: Write records to a file.

Aliases: `io-`, `out`, `o`

-------------------------------------
## `jira-out`

`jira-out` *[* *column-args ...* *]* 
Synopsis: Generate a Jira table lines.

Aliases: `jira-`, `jira`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // jira
||a||b||c||d||
|1|ab|3|foo|
|24|44|6|bar|
|134|5|9|baz|
|2|12|11|abc|
```

-------------------------------------

-------------------------------------

-------------------------------------
## `json-in`

`json-in` 
Synopsis: Parses JSON.

Aliases: `-json`

  Examples:

-------------------------------------

```none
$ cx in SOME.json // -json // h-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `json-out`

`json-out` 
Synopsis: Emits JSON.

Aliases: `json-`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // json-
[
{"a":1,"b":"ab","c":3,"d":"foo"},
{"a":24,"b":44,"c":6,"d":"bar"},
{"a":134,"b":5,"c":9,"d":"baz"},
{"a":2,"b":12,"c":11,"d":"abc"}
]
```

-------------------------------------

-------------------------------------

-------------------------------------
## `markdown-out`

`markdown-out`  *[* `--title=...` `--include-header`  *]* *[* *column-args ...* *]* 
Synopsis: Generate Markdown table lines.

Aliases: `markdown-`, `md`, `md-`, `markdown`

 Options            | Description             | Default | Values |
--------------------|-------------------------|---------|--------|
 `--title=...`      | Output title (caption). | none    |        |
 `--include-header` | Include a header.       | true    |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // markdown
| a     | b     | c     | d     |
| ----- | ----- | ----- | ----- |
| 1     | ab    | 3     | foo   |
| 24    | 44    | 6     | bar   |
| 134   | 5     | 9     | baz   |
| 2     | 12    | 11    | abc   |
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // md
| a     | b     | c     | d     |
| ----: | ----- | ----: | ----- |
|     1 | ab    |     3 | foo   |
|    24 | 44    |     6 | bar   |
|   134 | 5     |     9 | baz   |
|     2 | 12    |    11 | abc   |
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // md --title=SOME.CSV
| a     | b     | c     | d     |
| ----: | ----- | ----: | ----- |
|     1 | ab    |     3 | foo   |
|    24 | 44    |     6 | bar   |
|   134 | 5     |     9 | baz   |
|     2 | 12    |    11 | abc   |
[ SOME.CSV ]
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // md --title=SOME.CSV --no-include-header
|     1 | ab    |     3 | foo   |
|    24 | 44    |     6 | bar   |
|   134 | 5     |     9 | baz   |
|     2 | 12    |    11 | abc   |
[ SOME.CSV ]
```

-------------------------------------

-------------------------------------

-------------------------------------
## `meta-in`

`meta-in`  *[* `--clear-type`  *]* *[* *column-args ...* *]* 
Synopsis: Calculates various column metadata.

Aliases: `-meta`

 Options        | Description        | Default | Values |
----------------|--------------------|---------|--------|
 `--clear-type` | Clear column type. |         |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // -meta // h-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `meta-out`

`meta-out` *[* *column-args ...* *]* 
Synopsis: Generate a table of column metadata.

Aliases: `meta-`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // -meta // meta- // h-
name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred
a,a,true,0,0,,1,3,1,24,0,0,,,,String,String
b,b,true,1,1,,1,2,12,ab,0,0,,,,String,String
c,c,true,2,2,,1,2,11,9,0,0,,,,String,String
d,d,true,3,3,,3,3,abc,foo,0,0,,,,String,String
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // -meta // meta- // h-
name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred
a,a,true,0,0,Integer,1,3,1,134,0,0,,,right,Integer,Integer
b,b,true,1,1,Object,1,2,ab,ab,0,0,,,,Integer;String,Object
c,c,true,2,2,Integer,1,2,3,11,0,0,,,right,Integer,Integer
d,d,true,3,3,String,3,3,abc,foo,0,0,,,,String,String
```

-------------------------------------

-------------------------------------

-------------------------------------
## `meta-set`

`meta-set` *[* *column-args ...* *]* 
Synopsis: Set column meta.

Aliases: `meta=`, `set-meta`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // -meta // meta-set 'a:max_size=20;align=right' // md
| a                    | b     | c     | d     |
| -------------------: | ----- | ----- | ----- |
|                    1 | ab    | 3     | foo   |
|                   24 | 44    | 6     | bar   |
|                  134 | 5     | 9     | baz   |
|                    2 | 12    | 11    | abc   |
```

-------------------------------------

```none
$ cx in SOME.csv // -h // -meta // meta-set 'a:max_size=20;align=right;order=9' // meta- // cut name,order,max_size,align // md
| name  | order | max_size | align |
| ----- | ----: | -------: | ----- |
| b     |     1 |        2 |       |
| c     |     2 |        2 |       |
| d     |     3 |        3 |       |
| a     |     9 |       20 | right |
```

-------------------------------------

```none
$ cx in SOME.csv // -h // -meta // meta= 'c:name=newname;order=-1' // md
| newname | a     | b     | d     |
| ------- | ----- | ----- | ----- |
| 3       | 1     | ab    | foo   |
| 6       | 24    | 44    | bar   |
| 9       | 134   | 5     | baz   |
| 11      | 2     | 12    | abc   |
```

-------------------------------------

```none
$ cx in SOME.csv // -h // -meta // meta= 'c:some_option=123' // meta- // md
| name  | name_ | visible | order | index | type  | min_size | max_size | min_value | max_value | blanks | nulls | format | align | align_inferred | types    | type_inferred | some_option |
| ----- | ----- | ------- | ----: | ----: | ----- | -------: | -------: | --------- | --------- | -----: | ----: | ------ | ----- | -------------- | -------- | ------------- | ----------- |
| a     | a     | true    |     0 |     0 |       |        1 |        3 | 1         | 24        |      0 |     0 |        |       |                | String   | String        |             |
| b     | b     | true    |     1 |     1 |       |        1 |        2 | 12        | ab        |      0 |     0 |        |       |                | String   | String        |             |
| c     | c     | true    |     2 |     2 |       |        1 |        2 | 11        | 9         |      0 |     0 |        |       |                | String   | String        | 123         |
| d     | d     | true    |     3 |     3 |       |        3 |        3 | abc       | foo       |      0 |     0 |        |       |                | String   | String        |             |
```

-------------------------------------

-------------------------------------

-------------------------------------
## `nop`

`nop` 
Synopsis: Does nothing -- output is same as input.

Aliases: `noop`

-------------------------------------
## `parse`

`parse` *[* *column-args ...* *]* 
Synopsis: Parse strings into richer types.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // align // h-
a,b,c,d
    1,ab   ,    3,foo  
   24,44   ,    6,bar  
  134,5    ,    9,baz  
    2,12   ,   11,abc  
```

-------------------------------------

-------------------------------------

-------------------------------------
## `quote`

`quote`  *[* `--mode=...` `--strings-only`  *]* *[* *column-args ...* *]* 
Synopsis: Quote string values that would be ambigous or unprintable.

Aliases: `q`

 Options          | Description         | Default | Values                    |
------------------|---------------------|---------|---------------------------|
 `--mode=...`     | When to quote.      | "maybe" | maybe, everything, always |
 `--strings-only` | Ignore non-strings. |         |                           |

-------------------------------------
## `record-in`

`record-in`  *[* `--record-sep=...` `--field-sep=...`  *]* 
Synopsis: Parses records.

Aliases: `-record`

 Options            | Description       | Default          | Values |
--------------------|-------------------|------------------|--------|
 `--record-sep=...` | Record separator. | platform newline |        |
 `--field-sep=...`  | Field separator.  | ""               |        |

-------------------------------------
## `record-out`

`record-out`  *[* `--record-sep=...` `--field-sep=...`  *]* 
Synopsis: Generates records.

Aliases: `record-`

 Options            | Description       | Default          | Values |
--------------------|-------------------|------------------|--------|
 `--record-sep=...` | Record separator. | platform newline |        |
 `--field-sep=...`  | Field separator.  | ""               |        |

-------------------------------------
## `region`

`region` 
Synopsis: Select a range of rows.

Aliases: `range`

  Examples:

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region -1            // h-
id,a,b,c,X %
1100,-27,ylb ,39.6,39%
```

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region 2,4,6         // h-
id,a,b,c,X %
1002,77,ymt,0.4,48%
1004,-62,rcz ,1.2,127%
1006,67,hjn,"",187%
```

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region 11..14        // h-
id,a,b,c,X %
1011,39,axr,"",97%
1012,-38,wky,4.4,60%
1013,73,dmm ,4.8,197%
1014,48,gys,5.2,49%
```

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region 11...14       // h-
id,a,b,c,X %
1011,39,axr,"",97%
1012,-38,wky,4.4,60%
1013,73,dmm ,4.8,197%
```

-------------------------------------

```none
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

-------------------------------------

```none
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

-------------------------------------

```none
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

-------------------------------------

-------------------------------------

-------------------------------------
## `reject`

`reject` 
Synopsis: Reject rows for Ruby expressions that evaluation true.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // reject "a > 10" // h-
a,b,c,d
24,44,6,bar
134,5,9,baz
```

-------------------------------------

-------------------------------------

-------------------------------------
## `remove-empty`

`remove-empty` *[* *column-args ...* *]* 
Synopsis: Empty columns and rows are removed.

Aliases: `compact`

-------------------------------------
## `replace`

`replace`  *[* `--search=...` `--replace=...` `--global`  *]* *[* *column-args ...* *]* 
Synopsis: Replace by regex.

Aliases: `sub`

 Options         | Description                | Default | Values |
-----------------|----------------------------|---------|--------|
 `--search=...`  | Search for in all columns. |         |        |
 `--replace=...` | Replace matches with.      |         |        |
 `--global`      | Replace all occurances.    |         |        |

  Examples:

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region 1..5 // replace "x_:%;" // h-
id,a,b,c,X %
1001,79,ekl ,"",133
1002,77,ymt,0.4,48
1003,84,yis,0.8,12
1004,-62,rcz ,1.2,127
1005,-38,oub,1.6,9
```

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region 1..5 // replace --search=1 --replace=_ // h-
id,a,b,c,X %
_001,79,ekl ,"",_33%
_002,77,ymt,0.4,48%
_003,84,yis,0.8,_2%
_004,-62,rcz ,_.2,_27%
_005,-38,oub,_.6,9%
```

-------------------------------------

```none
$ cx in RANDOM.csv // -h // region 1..5 // replace --search=1 --replace= --global // h-
id,a,b,c,X %
00,79,ekl ,"",33%
002,77,ymt,0.4,48%
003,84,yis,0.8,2%
004,-62,rcz ,.2,27%
005,-38,oub,.6,9%
```

-------------------------------------

-------------------------------------

-------------------------------------
## `reverse`

`reverse` 
Synopsis: Reverse order of rows.

Aliases: `tac`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // reverse // h-
a,b,c,d
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
```

-------------------------------------

```none
$ cx in SOME.csv // reverse
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
a,b,c,d
```

-------------------------------------

-------------------------------------

-------------------------------------
## `row-id`

`row-id`  *[* `--name=...` `--type=...` `--start=...`  *]* 
Synopsis: Inserts a row id column.

 Options       | Description                | Default     | Values |
---------------|----------------------------|-------------|--------|
 `--name=...`  | Name of id column.         | "__rowid__" |        |
 `--type=...`  | Type: "integer" or "uuid". | "integer"   |        |
 `--start=...` | Start of integer ids.      | 1           |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // row-id --start=100 // h-
__rowid__,a,b,c,d
100,1,ab,3,foo
101,24,44,6,bar
102,134,5,9,baz
103,2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // row-id --name=id // h-
id,a,b,c,d
1,1,ab,3,foo
2,24,44,6,bar
3,134,5,9,baz
4,2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // row-id --type=uuid --name=uuid // h-
uuid,a,b,c,d
4ce19f1a-a12f-0c89-0429-311871528c45,1,ab,3,foo
035fb7a3-1142-14a1-1a68-e5d97aeb3594,24,44,6,bar
292172a7-b6b9-6ed5-46bc-c9486137efdb,134,5,9,baz
40bf24bd-85f1-a061-752b-bcd099c8eceb,2,12,11,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `select`

`select` 
Synopsis: Select rows for Ruby expressions that evaluation true.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // select "a > 10" // h-
a,b,c,d
24,44,6,bar
134,5,9,baz
```

-------------------------------------

-------------------------------------

-------------------------------------
## `sort`

`sort` *[* *column-args ...* *]* 
Synopsis: Sorts by specified columns.

Aliases: `s`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // sort d  // h-
a,b,c,d
2,12,11,abc
24,44,6,bar
134,5,9,baz
1,ab,3,foo
```

-------------------------------------

```none
$ cx in SOME.csv // -h // sort    // h-
a,b,c,d
1,ab,3,foo
134,5,9,baz
2,12,11,abc
24,44,6,bar
```

-------------------------------------

```none
$ cx in SOME.csv // -h //            sort a    // h-
a,b,c,d
1,ab,3,foo
134,5,9,baz
2,12,11,abc
24,44,6,bar
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse   // sort a    // h-
a,b,c,d
1,ab,3,foo
2,12,11,abc
24,44,6,bar
134,5,9,baz
```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse   // sort a:-  // h-
a,b,c,d
134,5,9,baz
24,44,6,bar
2,12,11,abc
1,ab,3,foo
```

-------------------------------------

-------------------------------------

-------------------------------------
## `sql-out`

`sql-out`  *[* `--table=...` `--transaction` `--rollback` `--commit` `--create` `--temporary` `--insert` `--varchar-size=...`  *]* *[* *column-args ...* *]* 
Synopsis: Generate SQL.

Aliases: `sql-`

 Options              | Description                       | Default | Values |
----------------------|-----------------------------------|---------|--------|
 `--table=...`        | Table name.                       |         |        |
 `--transaction`      | Emit a TRANSACTION block.         |         |        |
 `--rollback`         | Emit a ROLLBACK statement.        |         |        |
 `--commit`           | Emit a COMMIT statement.          |         |        |
 `--create`           | Emit a CREATE TABLE statement.    |         |        |
 `--temporary`        | CREATE TEMPORARY TABLE statement. |         |        |
 `--insert`           | Emit INSERT INTO statements.      |         |        |
 `--varchar-size=...` | VARCHAR(size).                    | 255     |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // sql- --table=SOME_TABLE --create
CREATE TABLE SOME_TABLE
(
  a INT,
  b TEXT,
  c INT,
  d VARCHAR(255)
);

```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // sql- --table=SOME_TABLE --insert
INSERT INTO SOME_TABLE
  (a, b, c, d)
VALUES
  (1, 'ab', 3, 'foo'),
  (24, '44', 6, 'bar'),
  (134, '5', 9, 'baz'),
  (2, '12', 11, 'abc');

```

-------------------------------------

```none
$ cx in SOME.csv // -h // parse // cut a b c // parse // meta= 'a:sql_type=VARCHAR(5)' // sql- --table=SOME_TABLE a b 'c:type=NUMERIC;default=-1' --create --temporary
CREATE TEMPORARY TABLE SOME_TABLE
(
  a VARCHAR(5),
  b TEXT,
  c NUMERIC DEFAULT -1
);

```

-------------------------------------

```none
$ cx in SOME.csv // -h // cut a b c // parse // meta= 'a:sql_type=VARCHAR(5)' // sql- --table=SOME_TABLE --insert
INSERT INTO SOME_TABLE
  (a, b, c)
VALUES
  ('1', 'ab', 3),
  ('24', '44', 6),
  ('134', '5', 9),
  ('2', '12', 11);

```

-------------------------------------

-------------------------------------

-------------------------------------
## `stats`

`stats` *[* *column-args ...* *]* 
Synopsis: Collect stats of a group of columns.

  Examples:

-------------------------------------

```none
$ cx in stats-data.csv // -h // parse // stats salary // md
| salary_count | salary_sum | salary_min | salary_max | salary_mean       | salary_median | salary_stddev    |
| -----------: | ---------: | ---------: | ---------: | ----------------: | ------------: | ---------------: |
|         17.0 |     1121.0 |       22.0 |      120.0 | 65.94117647058823 |          63.0 | 31.0908925348874 |
```

-------------------------------------

```none
$ cx in stats-data.csv // -h // parse // stats dept:g salary // md
| dept       | salary_count | salary_sum | salary_min | salary_max | salary_mean        | salary_median | salary_stddev      |
| ---------- | -----------: | ---------: | ---------: | ---------: | -----------------: | ------------: | -----------------: |
| sales      |          3.0 |      228.0 |       63.0 |       98.0 |               76.0 |          67.0 | 15.641824275533422 |
| marketing  |          6.0 |      286.0 |       22.0 |       87.0 | 47.666666666666664 |          33.5 | 27.686739706140113 |
| tech       |          3.0 |      250.0 |       60.0 |      120.0 |  83.33333333333333 |          70.0 | 26.246692913372705 |
| accounting |          5.0 |      357.0 |       40.0 |      115.0 |               71.4 |          47.0 | 33.672540741678525 |
```

-------------------------------------

```none
$ cx in stats-data.csv // -h // parse // stats job:g salary // md
| job   | salary_count | salary_sum | salary_min | salary_max | salary_mean | salary_median | salary_stddev      |
| ----- | -----------: | ---------: | ---------: | ---------: | ----------: | ------------: | -----------------: |
| a     |         11.0 |      506.0 |       22.0 |       70.0 |        46.0 |          45.0 | 16.387356545381397 |
| b     |          6.0 |      615.0 |       85.0 |      120.0 |       102.5 |         104.0 | 13.450526631573451 |
```

-------------------------------------

```none
$ cx in stats-data.csv // -h // parse // stats dept:g job:g salary // md
| dept       | job   | salary_count | salary_sum | salary_min | salary_max | salary_mean | salary_median | salary_stddev     |
| ---------- | ----- | -----------: | ---------: | ---------: | ---------: | ----------: | ------------: | ----------------: |
| sales      | a     |          2.0 |      130.0 |       63.0 |       67.0 |        65.0 |          65.0 |               2.0 |
| sales      | b     |          1.0 |       98.0 |       98.0 |       98.0 |        98.0 |          98.0 |               0.0 |
| marketing  | a     |          4.0 |      114.0 |       22.0 |       40.0 |        28.5 |          26.0 |  6.87386354243376 |
| marketing  | b     |          2.0 |      172.0 |       85.0 |       87.0 |        86.0 |          86.0 |               1.0 |
| tech       | a     |          2.0 |      130.0 |       60.0 |       70.0 |        65.0 |          65.0 |               5.0 |
| tech       | b     |          1.0 |      120.0 |      120.0 |      120.0 |       120.0 |         120.0 |               0.0 |
| accounting | a     |          3.0 |      132.0 |       40.0 |       47.0 |        44.0 |          45.0 | 2.943920288775949 |
| accounting | b     |          2.0 |      225.0 |      110.0 |      115.0 |       112.5 |         112.5 |               2.5 |
```

-------------------------------------

```none
$ cx in stats-data.csv // -h // parse // stats dept:g job:g salary:mean;median // md
| dept       | job   | salary_mean | salary_median |
| ---------- | ----- | ----------: | ------------: |
| sales      | a     |        65.0 |          65.0 |
| sales      | b     |        98.0 |          98.0 |
| marketing  | a     |        28.5 |          26.0 |
| marketing  | b     |        86.0 |          86.0 |
| tech       | a     |        65.0 |          65.0 |
| tech       | b     |       120.0 |         120.0 |
| accounting | a     |        44.0 |          45.0 |
| accounting | b     |       112.5 |         112.5 |
```

-------------------------------------

-------------------------------------

-------------------------------------
## `strip`

`strip` *[* *column-args ...* *]* 
Synopsis: Strip leading and trailing whitespace.

Aliases: `trim`

-------------------------------------
## `tee`

`tee` `pipelines` `...` 
Synopsis: Send input to multiple output pipelines.

Aliases: `t`

-------------------------------------
## `transpose`

`transpose`  *[* `--include-header`  *]* 
Synopsis: Transpose rows and columns.

 Options            | Description                     | Default | Values |
--------------------|---------------------------------|---------|--------|
 `--include-header` | Include header in first column. | true    |        |

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // transpose // h-
_COL_1,_COL_2,_COL_3,_COL_4,_COL_5
a,1,24,134,2
b,ab,44,5,12
c,3,6,9,11
d,foo,bar,baz,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // transpose --no-include-header // h-
_COL_1,_COL_2,_COL_3,_COL_4
1,24,134,2
ab,44,5,12
3,6,9,11
foo,bar,baz,abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `tsv-in`

`tsv-in` 
Synopsis: Parses TSV lines.

Aliases: `-tsv`

-------------------------------------
## `tsv-out`

`tsv-out` 
Synopsis: Generates TSV lines.

Aliases: `tsv-`

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // tsv-
a	b	c	d
1	ab	3	foo
24	44	6	bar
134	5	9	baz
2	12	11	abc
```

-------------------------------------

-------------------------------------

-------------------------------------
## `type-inference`

`type-inference` *[* *column-args ...* *]* 
Synopsis: Infer types from field strings.

Aliases: `-types`, `types`

-------------------------------------
## `uniq`

`uniq` *[* *column-args ...* *]* 
Synopsis: Emit only rows with uniq columns.

  Examples:

-------------------------------------

```none
$ cx in SOME.csv // -h // uniq d  // h-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

```none
$ cx in SOME.csv // -h // uniq    // h-
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

```none
$ cx in DUPLICATES.csv // -h // uniq   // h-
x,y,z
1,2,3
4,5,6
5,5,3
```

-------------------------------------

```none
$ cx in DUPLICATES.csv // -h // uniq x // h-
x,y,z
1,2,3
4,5,6
5,5,3
```

-------------------------------------

```none
$ cx in DUPLICATES.csv // -h // uniq y // h-
x,y,z
1,2,3
4,5,6
```

-------------------------------------

-------------------------------------

-------------------------------------

# Attribution

-------------------------------------
Copyright 2020 - Kurt Stephens
-------------------------------------
# Example Data

-------------------------------------

## DUPLICATES.csv

```none
x,y,z
1,2,3
4,5,6
1,2,3
5,5,3
```

-------------------------------------

## EMOS.csv

```none
2,12,11,abc
134,5,9,baz
24,44,6,bar
1,ab,3,foo
a,b,c,d
```

-------------------------------------

## HAS-UNUSED-COLUMNS.csv

```none
e,f,g,h
1,ab,,foo
24,,,bar
,5,,baz
,12,,abc
```

-------------------------------------

## OTHER.csv

```none
x,y
1,2
2,3
5,9
```

-------------------------------------

## RANDOM.csv

```none
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

-------------------------------------

## SOME.csv

```none
a,b,c,d
1,ab,3,foo
24,44,6,bar
134,5,9,baz
2,12,11,abc
```

-------------------------------------

## SOME.edn

```none
[
{:a 1 :b "ab" :c 3 :d "foo"}
{:a 24 :b 44 :c 6 :d "bar"}
{:a 134 :b 5 :c 9 :d "baz"}
{:a 2 :b 12 :c 11 :d "abc"}
]
```

-------------------------------------

## SOME.erb

```none
=== HEADER ===
columns = <%= input.header.columns.map(&:to_s) * ', ' %>
size    = <%= input.size %>

<% input.rows.each.with_index do | r, i | -%>
  Row <%= i %> : <%= r.to_a * ', ' %>
<% end -%>
=== FOOTER ===

```

-------------------------------------

## SOME.json

```none
[
{"a":1,"b":"ab","c":3,"d":"foo"},
{"a":24,"b":44,"c":6,"d":"bar"},
{"a":134,"b":5,"c":9,"d":"baz"},
{"a":2,"b":12,"c":11,"d":"abc"}
]
```

-------------------------------------

## plot.csv

```none
x,y1,y2
1,20,150
2.2,21,150
3.3,-10,120
4,35,132
20,16,75
25,67,80
50,99,55
55,10,60
65,95,55
100,110,40
```

-------------------------------------

## stats-data.csv

```none
dept,job,salary
sales,a,67
sales,a,63
sales,b,98
marketing,a,25
marketing,a,27
marketing,a,22
marketing,a,40
marketing,b,87
marketing,b,85
tech,a,60
tech,a,70
tech,b,120
accounting,a,45
accounting,a,47
accounting,a,40
accounting,b,110
accounting,b,115
```

-------------------------------------

-------------------------------------
