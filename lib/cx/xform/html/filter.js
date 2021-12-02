/*!
 * Row filtering.
 */
var cx_make_filter =
    function(table_id_) {
      var debug = false;
      
      var table_id = table_id_;
      
      var dom_table;
      var dom_cols;
      var dom_matched_row_count;
      var dom_filter_input;
      
      var col_map;
      
      function escapeRegExp(str) {
        return str.replaceAll(/[.*+?^$|{}()\[\]]/g, '\\$&');
      }

      function make_parser() {
        var pc = parser_combininator;
        var p;

        function with_type(t, p) {
          return pc.describe(
            'with_type',
            [t, p],
            pc.when(p,
                    function (str, inp) {
                      return {type: t,
                              str: str};
                    }));
        }

        var name       = pc.trim(pc.rx(/^([a-z0-9_]+):/i));
        
        var pat_quote  = pc.trim(pc.rx(/^"((\\"|[^"])*)"/));
        var pat_rx_    = pc.trim(pc.rx(/^\/((\\\/|[^/])*)\//));
        var pat_rx     = pc.pred(pat_rx_, pc.regexp_maybe);

        // var pat_word_  = pc.rx(/^\s*(\S+)/);
        var pat_word   = pc.and_(pc.not_(pc.or_(pat_quote, pat_rx, name)),
                                 pat_word_);
        
        var pat_word_  = pc.rx(/^\s*([^"/\s]+)/);
        var pat_word   = pat_word_;
        
        var pat        = pc.or_(with_type('quote', pat_quote),
                                with_type('rx',    pat_rx),
                                with_type('word',  pat_word));
        var col_pat  = pc.with_keys(['name', 'pat'],
                                    pc.seq(name, pat));
        col_pat = pc.when(col_pat,
                          function (pat, inp) {
                            return Object.assign({name: pat.name}, pat.pat);
                          });
        
        var bare_pat  =
            pc.when(pat,
                    function (pat, inp) {
                      return Object.assign({name: null}, pat);
                    });
        
        p = pc.all(pc.one_or_more(pc.or_(col_pat, bare_pat)));
        if ( debug )
          console.log('parser = %s', pc.description(p));

        p = pc.safe(p);
        
        return p;
      }
      var parser = make_parser();    
      
      function parse_filter_(col_map, filter_str) {
        // var debug = true;
        var pc = parser_combininator;
        var result = parser(filter_str);
        // console.log('parse result = %s', JSON.stringify(result, null, 2));
        
        if ( ! result ) {
          return false;
        }
        
        var pats_all = result[0];
        // console.log("pats_all = %s", JSON.stringify(pats_all, null, 2));
        if ( pats_all.length == 0 ) {
          return false;
        }
        
        pats_all.
          filter(pat => pat.type == 'rx').
          forEach(function (pat) {
            pat.rx_str = pat.str;
          });
        
        pats_all.
          filter(pat => pat.type == 'word').
          forEach(function(pat) {
            pat.rx_str = pc.escape_regexp(pat.str);
          });
        
        pats_all.
          filter(pat => pat.type == 'quote').
          forEach(function(pat) {
            var str = pat.str = pat.str.replace(/\\"/g, '"');
            pat.rx_str = pc.escape_regexp(str);
            if ( pat.name )
              pat.rx_str = '^' + pat.rx_str + '$';
          });

        var is_bare_pat = pat => pat.col === null;
        bare_pats = pats_all.filter(is_bare_pat);
        // console.log("bare_pats = %s", JSON.stringify(bare_pats, null, 2));

        var pats = pats_all.filter(pat => ! is_bare_pat(pat))
        // console.log("pats = %s", JSON.stringify(pats, null, 2));

        // Build a single RX for bare patterns:
        if ( bare_pats.length > 0 ) {
          var str = 
              bare_pats.
              map(pat => pat.str).
              join(' ');
          var rx_str =
              bare_pats.
              map(pat => pat.str).
              join('.+')
          pats.push({name:    false,
                     type:    'rx',
                     str:     str,
                     rx_str:  rx_str});
        }
        
        pats.forEach(function (pat) {
          var col_idx = pat.col_idx = col_map.get(pat.name);
          var extract_fn = pat.extract_fn = make_extract_fn(col_idx);
          pat.extract_fn_str = extract_fn.toString();
          
          var rx = pat.rx = pc.regexp_maybe(pat.rx_str);
          // pat.rx_str = rx.toString();
          var rx_fn = rx ? (str => str.match(rx)) : pc.constantly(true);
          pat.match_fn = function (row_data) {
            return rx_fn(extract_fn(row_data));
          }
          pat.match_fn_str = pat.match_fn.toString();
        });

        if ( debug )
          console.log("pats = %s", JSON.stringify(pats, null, 2));

        var match_fn = and_fns(
          pats.map(pat => pat.match_fn)
        );

        return match_fn;
      }

      function parse_filter(col_map, filter_str) {
        var pc = parser_combininator;
        try {
          return parse_filter_(col_map, filter_str);
        } catch ( err ) {
          console.log("parse_filter: error %s : filter_str %s",
                      pc.description(err.toString()),
                      pc.description(filter_str));
          return false; // function (row_data) { return false; };
        }
      }
      // parse_filter = parse_filter_;
      
      function make_extract_fn(col_idx) {
        return col_idx ?
          function (row_data) {
            return row_data[col_idx];
          } : extract_row_text_fn;
      }
      function extract_row_text_fn(row_data) {
        return row_data[0];
      }

      function and_fns(fns) {
        return function (row_data) {
          for ( var i = 0; i < fns.length; i ++ ) {
            if ( ! fns[i](row_data) ) {
              return false;
            }
          }
          return true;
        }
      }

      function make_row_data(tr) {
        var tds = Array.from(tr.getElementsByTagName("td")); //.toArray();
        var row_data = tds.map(function (td) {
          return td.textContent || td.innerText;
        });
        row_data[0] = row_data.slice(1).join(' ');
        return row_data;
      }

      function rows_by_fn(trs, match_row_fn) {
        // var debug = true;
        var n_rows_visible = 0;
        if ( debug )
          console.log("rows_by_fn : {{{");
        for (var i = 0; i < trs.length; i++) {
          var tr = trs[i];
          // console.log("tr = %s", tr.innerHTML);
          var matched = true;
          if ( match_row_fn ) {
            var row_data = make_row_data(tr);
            matched = match_row_fn(row_data);
            if ( debug && matched )
              console.log("rows_by_fn : %d / %d : matched", i, trs.length, row_data);
          }
          if ( matched ) {
            n_rows_visible ++;
            tr.style.display = '';
          } else {
            tr.style.display = 'none';
          }
        }
        if ( debug )
          console.log("rows_by_fn : }}} : %d / %d : matched", n_rows_visible, trs.length, row_data);
        return n_rows_visible;
      }

      function parse_row_fn(filter_str) {
        var row_fn = parse_filter(col_map, filter_str);
        return row_fn;
      }

      function filter_rows_now() {
        var filter_str = dom_filter_input.value;
        var row_fn = parse_row_fn(filter_str);
        var rows = dom_table.find(".cx-tbody tr").toArray();
        var n_rows_visible = rows_by_fn(rows, row_fn);
        dom_matched_row_count.textContent = n_rows_visible;
      }

      var timeout = null;
      function filter_rows() {
        if ( ! timeout ) {
          timeout = setTimeout(function() {
            filter_rows_now();
            if ( timeout ) {
              var tmp = timeout;
              timeout = null;
              clearTimeout(tmp);
            }
          }, 150);
        }
      }

      // Construct a map from cx column names to td offsets.
      function make_col_map(cols) {
        var col_map = new Map();
        cols.
          filter(function (th) {
            return th.getAttribute("data-filter-name");
          }).
          map(function(th) {
            var idx  = parseInt(th.getAttribute("data-column-index"));
            var name = th.getAttribute('data-filter-name');
            col_map.set(name, idx);
            var name = th.getAttribute('data-filter-name-full');
            col_map.set(name, idx);
          });
        col_map.set(false, 0);
        if ( debug )
          console.log("col_map = %j", col_map);
        return col_map;
      }

      function initalize(table_id_) {
        table_id = table_id_;
        var table = dom_table = $("#cx-table");
        var cols = dom_cols  = table.find(".cx-thead .cx-columns .cx-column").toArray();
        dom_filter_input = table.find(".cx-thead .cx-filter-input").toArray()[0]
        dom_matched_row_count = table.find(".cx-filter-matched-row-count").toArray()[0];
        col_map = make_col_map(cols);
        return {
          table_id: table_id,
          col_map: col_map,
          filter_rows: filter_rows,
          filter_rows_now: filter_rows_now
        };
      }

      return initalize(table_id_);
    };
