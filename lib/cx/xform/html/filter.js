/*!
 * Row filtering.
 */
function cx_filter_escapeRegExp(str) {
  return str.replaceAll(/[.*+?^$|{}()\[\]]/g, '\\$&');
}

var cx_filter_timeout = null;
function cx_filter_rows() {
  if ( ! cx_filter_timeout ) {
    cx_filter_timeout = setTimeout(function() {
      cx_filter_rows_now();
      if ( cx_filter_timeout ) {
        var tmp = cx_filter_timeout;
        cx_filter_timeout = null;
        clearTimeout(tmp);
      }
    }, 50);
  }
}

function cx_filter_make_parser() {
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

  var name       = pc.trim(pc.rx(/^([a-z0-9_]+):/i))
  var pat_quote  = pc.trim(pc.rx(/^"((\\"|[^"])*)"/))
  var pat_rx     = pc.trim(pc.rx(/^\/((\\\/|[^/])*)\//))
  var pat_word   = pc.rx(/^\s*(\S+)/)
  var pat        = pc.alt(with_type('quote', pat_quote),
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
  
  p = pc.all(pc.one_or_more(pc.alt(col_pat, bare_pat)));
  // console.log('parser = %s', pc.description(p));

  return p;
}
var cx_filter_parser_ = false;
function cx_filter_parser() {
  if ( ! cx_filter_parser_ )
    cx_filter_parser_ = cx_filter_make_parser();    
  return cx_filter_parser_;
}

function cx_filter_parse(col_map, filter_str) {
  var pc = parser_combininator;
  var p = cx_filter_parser();
  
  var result = p(filter_str);
  // console.log('parse result = %s', JSON.stringify(result, null, 2));
  
  if ( ! result ) {
    return function (texts) {
      return true;
    };
  }
  
  var pats_all = result[0];
  // console.log("pats_all = %s", JSON.stringify(pats_all, null, 2));

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
    var extract_fn = pat.extract_fn = cx_filter_extract_fn(col_idx);
    pat.extract_fn_str = extract_fn.toString();
    
    var rx = pat.rx = new RegExp(pat.rx_str);
    pat.match_fn = function (col_texts, row_text) {
      var text = extract_fn(col_texts, row_text);
      return text.match(rx);
    }
    pat.match_fn_str = pat.match_fn.toString();
  });

  // console.log("pats = %s", JSON.stringify(pats, null, 2));

  var match_fn = cx_filter_and_fns(
    pats.map(pat => pat.match_fn)
  );

  return match_fn;
}

function cx_filter_extract_fn(col_idx) {
  return col_idx ?
    function (row_data) {
      return row_data[col_idx];
    } :
  function (row_data) {
    return row_data[0];
  };
}

function cx_filter_and_fns(fns) {
  return function (texts) {
    for ( var i = 0; i < fns.length; i ++ ) {
      if ( ! fns[i](texts) ) {
        return false;
      }
    }
    return true;
  }
}

function cx_filter_match_fn_arg(tr) {
  var row_text = "";
  var tds = tr.getElementsByTagName("td");
  var texts = [ null ];
  // Note: j = 1 skips the row # column.
  for (var j = 1; j < tds.length; j++) {
    var td = tds[j];
    var col_text = td.textContent || td.innerText;
    texts.push(col_text);
    row_text += col_text + ' ';
  }
  texts[0] = row_text;
  return texts;
}

function cx_filter_rows_by_fn(trs, fn) {
  var n_rows_visible = 0;
  for (var i = 0; i < trs.length; i++) {
    var tr = trs[i];
    // console.log("tr = %s", tr.innerHTML);
    var visible = true;
    if ( fn ) {
      var row_text = "";
      var tds = tr.getElementsByTagName("td");
      // Note: j = 1 skips the row # column.
      for (var j = 1; j < tds.length; j++) {
        var td = tds[j];
        var txtValue = td.textContent || td.innerText;
        row_text += txtValue + ' ';
      }
      visible = fn(row_text);
    }
    if ( visible ) {
      n_rows_visible ++;
      tr.style.display = '';
    } else {
      tr.style.display = 'none';
    }
  }
  return n_rows_visible;
}

// Construct a map from cx column names to td offsets.
function cx_filter_col_map(cols) {
  var idx = 0;
  var col_name_to_index = new Map();
  // console.log("%s", cols.innerHTML);
  cols.
  map(function (th) {
    th.setAttribute("data-column-index", idx ++);
    return th;
  }).
  filter(function (th) {
    // console.log("th = %s", th.innerHTML);
    return th.getAttribute("data-filter-name");
  }).
  map(function(th) {
    // console.log("th = %s", th.innerHTML);
    var name = th.getAttribute('data-filter-name');
    var idx = th.getAttribute("data-column-index");
    col_name_to_index.set(name, parseInt(idx));
  });
  // console.log("%j", col_name_to_index);
  return col_name_to_index;
}

function cx_filter_row_fn(cols, filter_str) {
  var col_map = cx_filter_col_map(cols);
  var rx_str =
      filter_str.
      trim().
      split(/ +/g).
      map(cx_filter_escapeRegExp).
      join('.+');
  var rx = new RegExp(rx_str, 'im');

  var row_fn = rx_str !== '' ?
    function ( row_text ) {
      // console.log("row_text: %j", row_text);
      return rx.test(row_text)
    } : false;

  cx_filter_parse(col_map, filter_str); // TEST

  return row_fn;
}

function cx_filter_rows_now() {
  var table  = $("#cx-table");
  var cols   = table.find(".cx-thead .cx-columns .cx-column").toArray();
  var rows   = table.find(".cx-tbody tr").toArray();
  var filter_str = table.find(".cx-thead .cx-filter-input").toArray()[0].value;
  var row_fn = cx_filter_row_fn(cols, filter_str);
  var n_rows_visible = cx_filter_rows_by_fn(rows, row_fn);
  table.find(".cx-matched-row-count").toArray()[0].textContent = n_rows_visible;
}

function cx_filter_rows_now_old() {
  var table  = document.getElementById("cx-table");
  var thead  = document.getElementById("cx-thead");
  var filter = document.getElementById("cx-filter");
  var input  = document.getElementById("cx-filter-input");
  var tbody  = document.getElementById("cx-tbody");
  var cols   = thead.getElementsByClassName('cx-columns')[0];
  var rows   = tbody.getElementsByTagName("tr");

  var filter_str = input.value;
  var row_fn = cx_filter_row_fn(
    Array.from(cols.getElementsByClassName("cx-column")),
    filter_str);
  var n_rows_visible = cx_filter_rows_by_fn(rows, row_fn);
  document.getElementById("cx-matched-row-count").textContent = n_rows_visible;

  cx_filter_rows_now_new();
}

