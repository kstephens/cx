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
function cx_filter_rows_now() {
  var table  = document.getElementById("cx-table");
  var thead  = document.getElementById("cx-thead");
  var filter = document.getElementById("cx-filter");
  var input  = document.getElementById("cx-filter-input");
  var tbody  = document.getElementById("cx-tbody");
  var cols   = thead.getElementsByClassName('cx-columns')[0];
  var tr     = tbody.getElementsByTagName("tr");
  var n_rows_visible = 0;

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

  for (var i = 0; i < tr.length; i++) {
    var visible = true;
    if ( ! (rx_str === '') ) {
      var tds = tr[i].getElementsByTagName("td");
      var line_text = "";
      // Note: j = 1 skips the row # column.
      for (var j = 1; j < tds.length; j++) {
        var td = tds[j];
        var txtValue = td.textContent || td.innerText;
        line_text += txtValue + ' ';
      }
      visible = rx.test(line_text);
    }
    if ( visible ) {
      n_rows_visible ++;
      tr[i].style.display = '';
    } else {
      tr[i].style.display = 'none';
    }
  }

  document.getElementById("cx-matched-row-count").textContent = n_rows_visible;

  if ( cx_filter_timeout ) {
    var tmp = cx_filter_timeout;
    cx_filter_timeout = null;
    clearTimeout(tmp);
  }
}

