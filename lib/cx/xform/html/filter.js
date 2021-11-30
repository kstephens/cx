/*!
 * Basic row filtering.
 */
var cx_filter_timeout = null;
function cx_filter_escapeRegExp(str) {
  return str.replaceAll(/[.*+?^$|{}()\[\]]/g, '\\$&');
}
function cx_filter_rows() {
  if ( ! cx_filter_timeout ) 
    cx_filter_timeout = setTimeout(function() {
      cx_filter_rows_now();
    }, 50);
}
function cx_filter_rows_by_fn(trs, fn) {
  var n_rows_visible = 0;
  for (var i = 0; i < trs.length; i++) {
    var tr = trs[i];
    console.log("tr = %s", tr.innerHTML);
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
function cx_filter_rows_now() {
  var table  = document.getElementById("cx-table");
  var thead  = document.getElementById("cx-thead");
  var filter = document.getElementById("cx-filter");
  var input  = document.getElementById("cx-filter-input");
  var tbody  = document.getElementById("cx-tbody");
  var cols   = thead.getElementsByClassName('cx-columns')[0];
  var rows   = tbody.getElementsByTagName("tr");

  /////////////////////////////////
  // Construct a map from cx column names to td offsets.
  var idx = 0;
  var col_name_to_index = new Map();
  // console.log("%s", cols.innerHTML);
  Array.from(cols.
  getElementsByClassName("cx-column")).
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

  var filter_value = input.value.trim();
  var rx_str =
      filter_value.
      split(/ +/g).
      map(cx_filter_escapeRegExp).
      join('.+');
  var rx = new RegExp(rx_str, 'im');

  var row_fn = rx_str !== '' ?
    function ( row_text ) {
      console.log("row_text: %j", row_text);
      return rx.test(row_text)
    } : false;

  var n_rows_visible = cx_filter_rows_by_fn(rows, row_fn);
  document.getElementById("cx-matched-row-count").textContent = n_rows_visible;

  if ( cx_filter_timeout ) {
    var tmp = cx_filter_timeout;
    cx_filter_timeout = null;
    clearTimeout(tmp);
  }
}

