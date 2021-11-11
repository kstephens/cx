/*!
 * Basic row filtering.
 */
var cx_filter_timeout = null;
function cx_filter_rows() {
  if ( ! cx_filter_timeout ) 
    cx_filter_timeout = setTimeout(function() {cx_filter_rows_now();}, 50);
}
function cx_filter_rows_now() {
  var filter = document.getElementById("cx-filter");
  var input = document.getElementById("cx-filter-input");
  var filter_value = input.value.trim().toUpperCase();
  var table = document.getElementById("cx-table");
  var tbody = document.getElementById("cx-table-tbody");
  var tr = tbody.getElementsByTagName("tr");
  var n_rows_visible = 0;
  
  for (i = 0; i < tr.length; i++) {
    var tds = tr[i].getElementsByTagName("td")
    var display = "";
    if ( ! (filter_value === '') ) {
display = "none";
      for (j = 1; j < tds.length; j++) {
        var td = tds[j];
        var txtValue = td.textContent || td.innerText;
        if (txtValue.toUpperCase().indexOf(filter_value) > -1) {
          display = "";
          break;
        }
      }
    }
    if ( display != "none" ) n_rows_visible += 1;
    tr[i].style.display = display;
    document.getElementById("cx-matched-row-count").textContent = n_rows_visible;
  }
  if ( cx_filter_timeout ) {
    var tmp = cx_filter_timeout;
    cx_filter_timeout = null;
    clearTimeout(tmp);
  }
}

