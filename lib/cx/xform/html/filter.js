/*!
 * Row filtering.
 */
var cx_make_filter =
    function(table_id_) {
      var debug = false;
      
      var table_id = table_id_;

      var dom_window;
      var dom_table;
      var dom_rows;
      var dom_cols;
      var dom_matched_row_count;
      var dom_filter_input;
      
      var col_name_to_idx, col_idx_to_name;
      
      function escapeRegExp(str) {
        return str.replaceAll(/[.*+?^$|{}()\[\]]/g, '\\$&');
      }

      function to_col_idx(x) {
        return col_name_to_idx.get(x) || col_name_to_idx.get(col_idx_to_name.get(x));
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

        var name_rx    = pc.trim(pc.rx(/^:([a-z0-9_]+)/i));
        var name       = pc.pred(name_rx, to_col_idx);
        
        var pat_quote  = pc.trim(pc.rx(/^"((\\"|[^"])*)"/));
        var pat_rx_    = pc.trim(pc.rx(/^\/((\\\/|[^/])*)\//));
        var pat_rx     = pc.pred(pat_rx_, pc.regexp_maybe);
        var pat_word   = pc.trim(pc.rx(/^([^:"/]+)/));
        
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
      
      function parse_filter_fn_(filter_str) {
        // var debug = true;
        var pc = parser_combininator;
        var result = parser(filter_str);
        // console.log('parse result = %s', JSON.stringify(result, null, 2));
        
        if ( ! result ) return false;
        
        var pats_all = result[0];
        // console.log("pats_all = %s", JSON.stringify(pats_all, null, 2));
        if ( pats_all.length == 0 ) return false;
        
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
          var col_idx = pat.col_idx = to_col_idx(pat.name);
          var extract_fn = pat.extract_fn = make_extract_fn(col_idx);
          pat.extract_fn_str = extract_fn.toString();
          
          var rx = pat.rx = pc.regexp_maybe(pat.rx_str);
          // pat.rx_str = rx.toString();
          var rx_fn = rx ? (str => str.match(rx)) : false;
          pat.match_fn = rx_fn ?
            function (row_data) {
              return rx_fn(extract_fn(row_data));
            } : false;
          pat.match_fn_str = pat.match_fn.toString();
        });

        if ( debug )
          console.log("pats = %s", JSON.stringify(pats, null, 2));

        var match_fns = pats.map(pat => pat.match_fn);
        var match_fn = match_fns.indexOf(false) >= 0 ? false : and_fns(match_fns);

        if ( debug ) {
          console.log("match_fns = %s", JSON.stringify(match_fns));
          console.log("match_fn = %s", JSON.stringify(match_fn));
        }
        
        return match_fn;
      }

      function parse_filter_fn(filter_str) {
        var pc = parser_combininator;
        try {
          return parse_filter_fn_(filter_str);
        } catch ( err ) {
          console.log("parse_filter: error %s : filter_str %s",
                      pc.description(err.toString()),
                      pc.description(filter_str));
          return false; // function (row_data) { return false; };
        }
      }
      
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

      //////////////////////////////////////////////////
      
      function each_row(row_fn) {
        if ( debug )
          console.log("each_row : {{{ : %d", dom_rows.length);
        for (var i = 0; i < dom_rows.length; i++)
          row_fn(dom_rows[i]);
        if ( debug )
          console.log("each_row : }}} : %d", dom_rows.length);
      }
      
      //////////////////////////////////////////////////

      function reset_rows() {
        each_row(function(tr) {
          tr.style.display = '';
        });
        dom_matched_row_count.textContent = dom_rows.length;
      }
      
      function clear_filter() {
        reset_rows();
        dom_filter_input.value = '';
      }

      //////////////////////////////////////////////////

      function make_row_data(tr) {
        var tds = Array.from(tr.getElementsByTagName("td")); //.toArray();
        var row_data = tds.map(function (td) {
          return (td.textContent || td.innerText).trim();
        });
        row_data[0] = row_data.slice(1).join(' ');
        if ( debug )
          console.log("make_row_data = " + JSON.stringify(row_data));
        return row_data;
      }

      function get_row_data(tr) {
        var data;
        if ( ! (data = tr.cx_filter_row_data) )
          tr.cx_filter_row_data = data = make_row_data(tr);
        return data;
      }

      //////////////////////////////////////////////////
      
      function filter_rows_by_fn(match_row_fn) {
        var n_rows_visible = 0;
        each_row(function(tr) {
          var row_data = get_row_data(tr);
          var matched = match_row_fn(row_data);
          if ( matched ) {
            n_rows_visible ++;
            tr.style.display = '';
          } else {
            tr.style.display = 'none';
          }
          return matched;
        });
        return dom_matched_row_count.textContent = n_rows_visible;
      }

      function filter_rows_now() {
        var filter_str = dom_filter_input.value.trim();
        var input_ok, row_fn;
        if ( filter_str === '' ) {
          input_ok = true;
        } else {
          if ( (row_fn = parse_filter_fn(filter_str)) )
            input_ok = true;
        }
        
        if ( input_ok ) {
          dom_filter_input.classList.remove('cx-error');
        } else {
          dom_filter_input.classList.add('cx-error');
        }
        
        if ( row_fn ) {
          filter_rows_by_fn(row_fn);
        } else {
          reset_rows();
        }
      }

      function filter_rows_event(event) {
        // Do nothing if the event was already processed
        if ( ! event || event.defaultPrevented )
          return;
        switch ( event.which ) {
        case 37: // - left arrow
        case 39: // - right arrow
          break;
        case 38: // - up arrow
        case 40: // - down arrow
          // TODO: history
          break;
        default:
          if ( debug )
            console.log("event : %s : %s", event, event.which);
          filter_rows_now();
          return;
        }
        event.preventDefault();
      }
      
      var timeout = null;
      function filter_rows(event) {
        if ( ! timeout ) {
          timeout = setTimeout(function() {
            filter_rows_event(event);
            if ( timeout ) {
              var tmp = timeout;
              timeout = null;
              clearTimeout(tmp);
            }
          }, 500);
        }
      }

      // https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style
      function dump_style(element) {
        var out = "";
        var elementStyle = element.style;
        var computedStyle = window.getComputedStyle(element, null);

        for (prop in elementStyle) {
          if (elementStyle.hasOwnProperty(prop) || true) {
            out += "  " + prop + " = '" + elementStyle[prop] + "' > '" + computedStyle[prop] + "'\n";
          }
        }
        console.log(out)
        return out;
      }

      function pin_width(element) {
        var comp_style = dom_window.getComputedStyle(element, null);
        var style = element.style;
        style.width  = comp_style.width;
      }
      // Construct a map from cx column names to td offsets.
      function make_col_maps(table, cols) {
        col_name_to_idx = new Map();
        col_idx_to_name = new Map();
        cols.
          filter(function (th) {
            return th.getAttribute("data-filter-name");
          }).
          map(function(th) {
            var idx  = parseInt(th.getAttribute("data-column-index"));

            var name = th.getAttribute('data-filter-name');
            col_name_to_idx.set(name, idx);
            col_idx_to_name.set(idx, name);
            col_idx_to_name.set(idx + "", name);

            if ( debug )
              console.log("%s", JSON.stringify({name: name, idx: idx}));

            var name = th.getAttribute('data-filter-name-full');
            col_name_to_idx.set(name, idx);
            // dump_style(th);
            pin_width(th);
          });
        col_idx_to_name.set(0, false);
        col_idx_to_name.set("0", false);
        col_name_to_idx.set(false, 0);
        if ( debug ) {
          console.log("cols = %s", JSON.stringify(cols));
          console.log("col_name_to_idx = %s", JSON.stringify(col_name_to_idx));
          console.log("col_idx_to_name = %s", JSON.stringify(col_idx_to_name));
        }
      }

      function initalize(table_id_) {
        table_id = table_id_;
        dom_window = window;
        var table = dom_table = $("#" + table_id);
        var cols = dom_cols   = table.find(".cx-thead .cx-columns .cx-column").toArray();
        var rows = dom_rows   = table.find(".cx-tbody tr").toArray();
        dom_filter_input      = table.find(".cx-thead .cx-filter-input").toArray()[0]
        dom_matched_row_count = table.find(".cx-filter-matched-row-count").toArray()[0];
        make_col_maps(table, cols);

        pin_width(dom_table.toArray()[0]);

        return {
          table_id: table_id,
          col_name_to_idx: col_name_to_idx,
          col_idx_to_name: col_idx_to_name,
          filter_rows: filter_rows,
          filter_rows_now: filter_rows_now,
          filter_rows_event: filter_rows_event,
          clear_filter: clear_filter
        };
      }

      return initalize(table_id_);
    };
