/*!
 * Basic row filtering.
 */
var cx_filter_timeout = null;
function cx_filter_rows() {
  if ( ! cx_filter_timeout ) 
    cx_filter_timeout = setTimeout(function() {cx_filter_rows_now();}, 50);
}
function cx_filter_rows_now() {
  // Declare variables
  var input = document.getElementById("cx-filter");
  var filter = input.value.trim().toUpperCase();
  var table = document.getElementById("cx-table");
  var tbody = document.getElementById("cx-table-tbody");
  var tr = tbody.getElementsByTagName("tr");

  for (i = 0; i < tr.length; i++) {
    var tds = tr[i].getElementsByTagName("td")
    var display = "";
    if ( ! (filter === '') ) {
display = "none";
    for (j = 1; j < tds.length; j++) {
      var td = tds[j];
      var txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        display = "";
        break;
      }
    }
    }
    tr[i].style.display = display;
  }
  if ( cx_filter_timeout ) {
    var tmp = cx_filter_timeout;
    cx_filter_timeout = null;
    clearTimeout(tmp);
  }
}

