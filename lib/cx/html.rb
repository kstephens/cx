# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cgi/util'

require 'cx/pipe'
require 'cx/csv_safe'

module CX
  class HtmlOut < Pipe
  include Pipe::NeedsHeader
  include Pipe::Format
  def init_more!
    super
    @raw_columns = Set.new((opts[:raw] || '')
                             .strip.split(/\s+|\s*,\s*/, -1)
                             .map(&:to_sym)
                             .uniq)
    self
  end
  def call input, env
    header = input.header!
    cols = header.cols
    colspan = 1 + cols.size
    right = {style: 'text-align: right;'}
    output = new_table(input)
    h = HTML.new(output)
    h.html do
      h.head do
        x = opts[:title] and h.title(x)
        h << HTML_HEAD
        x = opts[:head]  and h.raw!(x)
      end
      h.body do
        x = opts[:body_head] and h.html(x)
        h.div(id: 'cx-content', class: 'cx-content') do
        x = opts[:title] and h.div({id: 'cx-title', class: 'cx-title'}, x)
        h.table(id: 'cx-table', class: 'cx-table') do
          h.thead do
            if opts[:filtering]
              h.tr(class: 'cx-filter') do
                h.span(class: 'cx-filter') do
                  h.th(class: 'cx-filter', colspan: colspan) do
                    h.input({type: "text",
                             id: 'cx-filter',
                             class: "cx-filter",
                             onkeyup: "cx_filter_rows()",
                             placeholder: "#{UNICODE[:search]} Filter..."})
                  end
                end
              end
            end
            h.tr do
              a = {class: 'cx-column-header'}
              h.th(a.merge("data-sort-method" => :number), "#")
              cols.each do | c |
                a = a.merge("data-sort-method" => :number) if c.justify == :right
                h.th(a, c)
              end
            end
          end
          size = input.size
          h.tbody({id: "cx-table-tbody"}) do
            td_attrs = cols.map{|c| c.justify == :right ? right : nil}
            raw_cols = cols.map{|c| @raw_columns.include?(c.name)}
            inds = cols.map{|c| header[c].to_i }
            ri = 0
            input.each_shift do | r |
              ri += 1
              row_tooltip = "Row #{ri} / #{size}"
              # row_tooltipe << ": #{r[inds[0]]}" # TODO: make this optional
              h.tr(title: row_tooltip) do
                h.td(right, ri)
                inds.each_with_index do | ci, i |
                  h.td(td_attrs[i]) do
                    if raw_cols[i]
                      h.raw!(r[ci])
                    else
                      h.text(r[ci])
                    end
                  end
                end
              end
            end
          end
        end
        end
        x = opts[:body_foot] and h.raw!(x)
      end
      h << HTML_FOOT
    end
    env[:content_type] = 'text/html'
    app.call(output, env)
  end

  UNICODE = {
    # Left-Pointing Magnifying Glass : U+1F50D
    search: "🔍",
  }

  class HTML < Object # BasicObject
    def initialize out
      @out = out
      @html_sep   = ::Hash[%w(span td th title meta).map{|t| [t.to_sym, ""]}]
      @html_open  = ::Hash.new{|h, tag| h[tag.to_sym] = "<#{tag}>".freeze}
      @html_close = ::Hash.new{|h, tag| h[tag.to_sym] = "</#{tag}>".freeze}
    end
    
    def _tag tag, attrs = nil, content = nil, &blk
      tag = tag.to_sym
      case
      when ::Hash === attrs
        attrs = attrs.map{|k,v| v.nil? || " #{k}='#{v}'"}.compact
        attrs = attrs.empty? ? nil : attrs.join(' ')
      when ::String === attrs && ! content
        content = attrs
        attrs = nil
      end
      ws = @html_sep[tag] ||= "\n"

      self << (attrs ? "<#{tag} #{attrs}>" : @html_open[tag]) << ws

      case
      when content
        close = true
        text(content)
      when blk
        close = true
        yield self
      else
        close = false
      end
      
      self << @html_close[tag] << "\n" if close
      nil
    end
    
    def raw! x ; @out.write x.to_s ; self ; end
    alias :<< :raw!
    def text x
      raw! ::CGI::escapeHTML(Typing.coerce(x, String))
    end

    def method_missing sel, *args, &blk
      _tag(sel, *args, &blk)
    end
  end
  
  HTML_HEAD = <<END
<style type="text/css">
body {
font-family: Arial, Helvetica, sans-serif;
background-color: #000;
color: #eee;
}
.cx-title {
  text-align: center
}
div.cx-content {
  display: inline-block;
}
table {
  border-collapse: collapse;
}
thead th {
  background-color: #333;
  border: 0.1rem solid #111
}
tr:hover {
  background-color: #444;
}
tr:nth-child(even) {
  background-color: #222;
}
th, td {
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #555;
}
a:link {
  color: inherit;
  text-decoration: none;
}
a:active {
  color: inherit;
  text-decoration: none;
}
a:visited {
  color: inherit;
  text-decoration: none;
}
a:hover {
  color: inherit;
  text-decoration: underline;
}

# https://css-tricks.com/position-sticky-and-table-headers/
table.cx-table {
  position: relative,
}
th.cx-column-header {
  position: sticky;
  top: 0;
}

th.cx-filter {
  position: sticky;
  left: 0;
}
input.cx-filter {
  width: 15em;
  float: left;
}

</style>
END
  
  HTML_FOOT = <<END
<script type="text/javascript">
/*!
 * tablesort v5.1.0 (2018-09-14)
 * http://tristen.ca/tablesort/demo/
 * Copyright (c) 2018 ; Licensed MIT
*/
!function(){function a(b,c){if(!(this instanceof a))return new a(b,c);if(!b||"TABLE"!==b.tagName)throw new Error("Element must be a table");this.init(b,c||{})}var b=[],c=function(a){var b;return window.CustomEvent&&"function"==typeof window.CustomEvent?b=new CustomEvent(a):(b=document.createEvent("CustomEvent"),b.initCustomEvent(a,!1,!1,void 0)),b},d=function(a){return a.getAttribute("data-sort")||a.textContent||a.innerText||""},e=function(a,b){return a=a.trim().toLowerCase(),b=b.trim().toLowerCase(),a===b?0:a<b?1:-1},f=function(a,b){return function(c,d){var e=a(c.td,d.td);return 0===e?b?d.index-c.index:c.index-d.index:e}};a.extend=function(a,c,d){if("function"!=typeof c||"function"!=typeof d)throw new Error("Pattern and sort must be a function");b.push({name:a,pattern:c,sort:d})},a.prototype={init:function(a,b){var c,d,e,f,g=this;if(g.table=a,g.thead=!1,g.options=b,a.rows&&a.rows.length>0)if(a.tHead&&a.tHead.rows.length>0){for(e=0;e<a.tHead.rows.length;e++)if("thead"===a.tHead.rows[e].getAttribute("data-sort-method")){c=a.tHead.rows[e];break}c||(c=a.tHead.rows[a.tHead.rows.length-1]),g.thead=!0}else c=a.rows[0];if(c){var h=function(){g.current&&g.current!==this&&g.current.removeAttribute("aria-sort"),g.current=this,g.sortTable(this)};for(e=0;e<c.cells.length;e++)f=c.cells[e],f.setAttribute("role","columnheader"),"none"!==f.getAttribute("data-sort-method")&&(f.tabindex=0,f.addEventListener("click",h,!1),null!==f.getAttribute("data-sort-default")&&(d=f));d&&(g.current=d,g.sortTable(d))}},sortTable:function(a,g){var h=this,i=a.cellIndex,j=e,k="",l=[],m=h.thead?0:1,n=a.getAttribute("data-sort-method"),o=a.getAttribute("aria-sort");if(h.table.dispatchEvent(c("beforeSort")),g||(o="ascending"===o?"descending":"descending"===o?"ascending":h.options.descending?"descending":"ascending",a.setAttribute("aria-sort",o)),!(h.table.rows.length<2)){if(!n){for(;l.length<3&&m<h.table.tBodies[0].rows.length;)k=d(h.table.tBodies[0].rows[m].cells[i]),k=k.trim(),k.length>0&&l.push(k),m++;if(!l)return}for(m=0;m<b.length;m++)if(k=b[m],n){if(k.name===n){j=k.sort;break}}else if(l.every(k.pattern)){j=k.sort;break}for(h.col=i,m=0;m<h.table.tBodies.length;m++){var p,q=[],r={},s=0,t=0;if(!(h.table.tBodies[m].rows.length<2)){for(p=0;p<h.table.tBodies[m].rows.length;p++)k=h.table.tBodies[m].rows[p],"none"===k.getAttribute("data-sort-method")?r[s]=k:q.push({tr:k,td:d(k.cells[h.col]),index:s}),s++;for("descending"===o?q.sort(f(j,!0)):(q.sort(f(j,!1)),q.reverse()),p=0;p<s;p++)r[p]?(k=r[p],t++):k=q[p-t].tr,h.table.tBodies[m].appendChild(k)}}h.table.dispatchEvent(c("afterSort"))}},refresh:function(){void 0!==this.current&&this.sortTable(this.current,!0)}},"undefined"!=typeof module&&module.exports?module.exports=a:window.Tablesort=a}();

/*!
 * tablesort v5.1.0 (2018-09-14)
 * http://tristen.ca/tablesort/demo/
 * Copyright (c) 2018 ; Licensed MIT
*/
!function(){var a=function(a){return a.replace(/[^\-?0-9.]/g,"")},b=function(a,b){return a=parseFloat(a),b=parseFloat(b),a=isNaN(a)?0:a,b=isNaN(b)?0:b,a-b};Tablesort.extend("number",function(a){return a.match(/^[-+]?[£\x24Û¢´€]?\d+\s*([,\.]\d{0,2})/)||a.match(/^[-+]?\d+\s*([,\.]\d{0,2})?[£\x24Û¢´€]/)||a.match(/^[-+]?(\d)*-?([,\.]){0,1}-?(\d)+([E,e][\-+][\d]+)?%?$/)},function(c,d){return c=a(c),d=a(d),b(d,c)})}();

  new Tablesort(document.getElementById('cx-table'));

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

</script>
END
end

end
