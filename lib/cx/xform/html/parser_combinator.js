/*
function nocache(module) {
  require("fs")
    .watchFile(require("path").resolve(module),
               () => {
                 delete require.cache[require.resolve(module)]});
}
*/

var parser_combininator
  = (
    function () {
      var state = {};
      //////////////////////////////////////
      // Helpers:

      function zip(arrays) {
        return arrays[0].map(
          function(_,i) {
            return arrays.map(
              function(array) {
                return array[i];
              });
          });
      }

      function escape_regexp(str) {
        return str.replace(/[.*+?^$|{}()\[\]]/g, '\\$&');
      }

      //////////////////////////////////////
      // Documentation:
      
      function description(x) {
        switch ( typeof x ) {
        case 'undefined':
          return'undefined';
        case 'number':
          return x + '';
        case 'boolean':
          return x + '';
        case 'string':
          return JSON.stringify(x);
        case 'function':
          return x.description || 'function(){...}';
        case 'object':
          if ( x === null ) {
            return null;
          }
          return JSON.stringify(x);
        default:
          throw typeof(x);
        };
      }
      function wrap_debug(p) {
        var desc = description(p);
        var p1 = function (inp) {
          console.log("PC: %s(%s) => ...",
                      desc,
                      description(inp));
          var result = p(inp);
          console.log("PC: %s(%s) => %s",
                      desc,
                      description(inp),
                      description(result));
          return result;
        };
        p1.description = desc;
        return p1;
      }
        
      function named(s, p) {
        p.description = s;
        var p1 = wrap_debug(p);
        return p1;
      }
      function describe(s, args, p) {
        return named(s + '(' + args.map(description).join(', ') + ')', p);
      }
      
      //////////////////////////////////////

      function falsely_or(m) {
        return m ? false : m;
      }
      function matched(m) {
        return m === false ? false : m;
      }
      function match_item(m) {
        return matched(m) ? m[0] : null;
      }
      function match_input(m) {
        return matched(m) ? m[1] : null;
      }
      function match_empty(m) {
        return matched(m) && m[1] === '';
      }

      //////////////////////////////////////
      // Alternation:
     
      function alt() {
        var ps = Array.from(arguments);
        return describe(
          'alt',
          ps,
          function (inp) {
            for ( var i = 0; i < ps.length; ++ i ) {
              if ( matched(m = ps[i](inp)) ) {
                return m;
              }
            }
            return false;
          });
      }
      
      //////////////////////////////////////
      // Sequences:
      
      function all(p) {
        return describe(
          'all',
          [p],
          function (inp) {
            var m = p(inp);
            return matched(m) && match_empty(m) ? m : false;
          });
      }
      
      function one(p) {
        return describe(
          'one',
          [p],
          function (inp) {
            var m = p(inp);
            if ( matched(m) ) {
              return [ [ m[0] ], m[1] ]
            } else {
              return false;
            }
          });
      }

      function zero_or_more(p) {
        return describe(
          'zero_or_more',
          [p],
          function (inp) {
            var items = [ ];
            var m;
            while ( matched(m = p(inp)) ) {
              items.push(m[0]);
              inp = m[1];
            }
            return [ items, inp ];
          });
      }

      function at_least(n, p) {
        var zom = zero_or_more(p);
        return describe(
          'at_least',
          [n, p],
          function (inp) {
            return matched(m = zom(inp)) && m[0].length >= n ? m : false;
          });
      }
      
      function one_or_more(p) {
        return describe(
          'one_or_more',
          [p],
          at_least(1, p));
      }
      
      function seq() {
        var ps = Array.from(arguments);
        return describe(
          'seq',
          ps,
          function (inp) {
            var items = [ ];
            for ( var i = 0; i < ps.length; ++ i ) {
              var p = ps[i];
              if ( matched(m = p(inp)) ) {
                items.push(m[0]);
                inp = m[1];
              } else {
                return false;
              }
            }
            return items.length == ps.length ? [ items, inp ] : false;
          });
      }

      //////////////////////////////////////
      // Leaf fns:
      
      function eq(str) {
        return describe(
          'eq',
          [str],
          function (inp) {
            return inp === str ? [ str, '' ] : false;
          });
      }
      function eos() {
        return describe(
          'eos',
          [],
          eq(''));
      }
      function rx(re) {
        return describe(
          'rx',
          [re],
          function (inp) {
            var m = inp.match(re);
            // console.log("re = %s, inp = %j, m = %j", re, inp, m);
            return m ? [ m[1] || m[0], inp.substring(m.index + m[0].length) ] : false;
          });
      }
      function trim(p) {
        return describe(
          'trim',
          [p],
          function (inp) {
            var m = p(inp.trim());
            return matched(m) ? [ m[0], m[1].trim() ] : false; 
          });
      }

      //////////////////////////////////////
      // Contitional binding:

      function with_keys(ns, p) {
        return describe(
          'with_keys',
          [ns, p],
          function (inp) {
            var m;
            if ( matched(m = p(inp)) ) {
              m = [
                Object.fromEntries(zip([ns, m[0]])),
                m[1]
              ];
            }
            return m;
          }
        );
      }
      
      function when(p,f) {
        return describe(
          'when',
          [p, f],
          function (inp) {
            var m;
            if ( matched(m = p(inp)) ) {
              m = [
                f(m[0], m[1]),
                m[1]
              ];
            }
            return m;
          }
        );
      }

      //////////////////////////////////////
      // Tests:
      
      function run_tests() {
        var p;
        function t(inp, expected) {
          console.log("\n  ------------------------------");
          console.log("  parser:    %s", description(p));
          console.log("  input:     %j", inp);
          console.log("  expected:  %j", expected);
          var actual = p(inp);
          console.log("  actual:    %j", actual);
          console.log("  ------------------------------");
          if ( JSON.stringify(expected) !== JSON.stringify(actual) ) {
            throw 'test failed!';
          }
          return actual;
        }
        
        p = eq('abc');
        t('abc',
          ['abc', '']);
        t(' abc',
          false);

        p = rx(/^[a-z]+/);
        t('abc REST',
         ["abc"," REST"]);
        t(' abc REST',
         false);
        t('1 REST',
         false);

        p = trim(rx(/^[a-z]+/));
        t('abc REST',
         ["abc","REST"]);
        t(' abc REST',
         ["abc","REST"]);
        t('1 REST',
         false);

        p = alt(rx(/^[a-z]+/), rx(/^\d+/));
        t('abc REST',
         ["abc"," REST"]);
        t('1 REST',
         ["1"," REST"]);
        t(' 1 REST',
         false);

        p = alt(with_keys(['key'],
                          rx(/^[a-z]+/)),
                with_keys(['val'],
                          rx(/^\d+/)));
        t('abc REST',
         [{"key":"a"}," REST"]);
        t('1 REST',
          [{"val":"1"}," REST"]);
        t(' 1 REST',
         false);

        p = seq(rx(/^[a-z]+/), rx(/^\d+/));
        t('abc REST',
         false);
        t('abc 123 REST',
         false);
        t('abc123 REST',
         [["abc","123"]," REST"]);

        p = seq(trim(rx(/^[a-z]+/)),
                trim(rx(/^\d+/)));
        t('abc 123  REST',
         [["abc","123"],"REST"]);
        t('  abc   123   REST',
         [["abc","123"],"REST"]);

        p = seq(trim(rx(/^[a-z]+/)),
                trim(rx(/^\d+/)),
                eos());
        t('abc 123',
          [["abc","123",""],""]);
        t('  AbC   1 REST',
         false);

        p = all(
          seq(trim(rx(/^[a-z]+/)),
              trim(rx(/^\d+/))));
        t('abc 123',
          [["abc","123"],""]);
        t('  AbC   1 REST',
         false);

        p = one(
          seq(trim(rx(/^[a-z]+/)),
              trim(rx(/^\d+/))));
        t('abc 123',
          [[["abc","123"]],""]);
        t('  abc   123   REST',
          [[["abc","123"]],"REST"]);
        t(' OTHER',
         false);

        p = zero_or_more(trim(rx(/^\d+/)));
        t('  REST',
          [[],"  REST"]);
        t('123  REST',
         [["123"],"REST"]);
        t('123 45 REST',
         [["123","45"],"REST"]);

        p =
          zero_or_more(seq(trim(rx(/^[a-z]+:/)),
                           trim(rx(/^\d+/))));
        t('  REST',
          [[], '  REST']);
        t('a: 123  REST',
          [[["a:","123"]],
           "REST"]);
        t('a: 123 b: 45 REST',
          [[["a:","123"],
            ["b:","45"]],
           "REST"]);

        p =
          one_or_more(
            with_keys(['key', 'val'],
                      seq(trim(rx(/^[a-z]+/)),
                          trim(rx(/^\d+/)))));
        t('  REST',
          false);
        t('abc 123  REST',
          [[{"key":"abc","val":"123"}],
           "REST"]);
        t(' abc 123 xyz 45REST',
          [[{"key":"abc","val":"123"},
            {"key":"xyz","val":"45"}],
           "REST"]);

        //////////////////////////////

        function with_type(t, p) {
          return describe(
            'with_type',
            [t, p],
            when(p,
                 function (val) {
                   return {type: t,
                           val:  val};
                 }));
        }
          
        var col        = trim(rx(/^([a-z0-9_]+):/i))
        var pat_quote  = trim(rx(/^"((\\"|[^"])*)"/))
        var pat_rx     = trim(rx(/^\/((\\\/|[^/])*)\//))
        var pat_word   = rx(/^\s*(\S+)/)
        var pat        = alt(with_type('quote', pat_quote),
                             with_type('rx',    pat_rx),
                             with_type('word',  pat_word));
        var col_pat    = with_keys(['col', 'pat'],
                                   seq(col, pat));
        var bare_word  =
            when(trim(pat_word),
                 function (val) {
                   return {col: "*",
                           pat: {type: 'word',
                                 val: val}};
                 });
        p = all(one_or_more(alt(col_pat, bare_word)));
        
        t(' ',
          false);

        t(' word1  word2 123  ',
          [[{"col":"*", "pat":{"type":"word","val":"word1"}},
            {"col":"*", "pat":{"type":"word","val":"word2"}},
            {"col":"*", "pat":{"type":"word","val":"123"}}],
           ""]
         );
        
        t('word:123',
          [[{"col":"word",
             "pat":{"type":
                  "word",
                  "val":"123"}}],
           ""]);
        t('  quote:  "quoted \\" string"  ',
          [[{"col":"quote",
             "pat":{"type":"quote",
                  "val":"quoted \\\" string"}}],
           ""]);
        t('rx:/a? \\/+regex*/',
          [[{"col":"rx",
             "pat":{"type":"rx",
                  "val":"a? \\/+regex*"}}],""]);
        
        r =
          t(' this:"q. \\"ed" word1  that:word2 123.5 other: /regex\\? */ ',
            [[{"col":"this",
               "pat":{"type":"quote",
                      "val":"q. \\\"ed"}},
              {"col":"*",
               "pat":{"type":"word",
                      "val":"word1"}},
              {"col":"that",
               "pat":{"type":"word",
                      "val":"word2"}},
              {"col":"*",
               "pat":{"type":"word",
                      "val":"123.5"}},
              {"col":"other",
               "pat":{"type":"rx",
                      "val":"regex\\? *"}}],
             ""]
           );
        var col_pats = r[0];
        var is_bare_pat = x => x.col === '*';

        console.log("%s", JSON.stringify(col_pats, null, 2));
        col_pats.
          filter(x => x.pat.type == 'rx').
          forEach(x => x.pat.rx_str = x.pat.val);
        col_pats.
          filter(x => x.pat.type == 'word').
          forEach(x => x.pat.rx_str = escape_regexp(x.pat.val));
        col_pats.
          filter(x => x.pat.type == 'quote').
          forEach(function(x) {
            x.pat.val = x.pat.val.replace(/\\"/g, '"');
            x.pat.rx_str = '^' + escape_regexp(x.pat.val) + '$';
          });

        bare_pats_rx_str =
          col_pats.
          filter(is_bare_pat).
          map(x => x.pat.rx_str).
          join('.+')
        col_pats = col_pats.filter(x => ! is_bare_pat(x))
        if ( bare_pats_rx_str !== '' ) {
          col_pats.push({col: "*",
                         pat: {type: 'rx',
                               val: bare_pats_rx_str,
                               rx_str: bare_pats_rx_str}})
        }
        console.log("%s", JSON.stringify(col_pats, null, 2));

      }
      // run_tests();
      
      return {
        matched: matched,
        alt: alt,
        all: all,
        one: one,
        zero_or_more: zero_or_more,
        at_least: at_least,
        one_or_more: one_or_more,
        seq: seq,
        eq: eq,
        eos: eos,
        rx: rx,
        trim: trim,
        with_keys: with_keys,
        when: when,
        escape_regexp: escape_regexp,
        description: description,
        named: named,
        describe: describe,
        run_tests: function() {
          parser_combinator_test();
        }
     };
  }
)();

//////////////////////////////////////
// Tests:
      
function parser_combinator_test() {
  var pc = parser_combinator;
  var p;
  function t(inp, expected) {
    console.log("\n  ------------------------------");
    console.log("  parser:    %s", description(p));
    console.log("  input:     %j", inp);
    console.log("  expected:  %j", expected);
    var actual = p(inp);
    console.log("  actual:    %j", actual);
    console.log("  ------------------------------");
    if ( JSON.stringify(expected) !== JSON.stringify(actual) ) {
      throw 'test failed!';
    }
    return actual;
  }

  p = eq('abc');
  t('abc',
    ['abc', '']);
  t(' abc',
    false);

  p = rx(/^[a-z]+/);
  t('abc REST',
   ["abc"," REST"]);
  t(' abc REST',
   false);
  t('1 REST',
   false);

  p = trim(rx(/^[a-z]+/));
  t('abc REST',
   ["abc","REST"]);
  t(' abc REST',
   ["abc","REST"]);
  t('1 REST',
   false);

  p = alt(rx(/^[a-z]+/), rx(/^\d+/));
  t('abc REST',
   ["abc"," REST"]);
  t('1 REST',
   ["1"," REST"]);
  t(' 1 REST',
   false);

  p = alt(with_keys(['key'],
                    rx(/^[a-z]+/)),
          with_keys(['val'],
                    rx(/^\d+/)));
  t('abc REST',
   [{"key":"a"}," REST"]);
  t('1 REST',
    [{"val":"1"}," REST"]);
  t(' 1 REST',
   false);

  p = seq(rx(/^[a-z]+/), rx(/^\d+/));
  t('abc REST',
   false);
  t('abc 123 REST',
   false);
  t('abc123 REST',
   [["abc","123"]," REST"]);

  p = seq(trim(rx(/^[a-z]+/)),
          trim(rx(/^\d+/)));
  t('abc 123  REST',
   [["abc","123"],"REST"]);
  t('  abc   123   REST',
   [["abc","123"],"REST"]);

  p = seq(trim(rx(/^[a-z]+/)),
          trim(rx(/^\d+/)),
          eos());
  t('abc 123',
    [["abc","123",""],""]);
  t('  AbC   1 REST',
   false);

  p = all(
    seq(trim(rx(/^[a-z]+/)),
        trim(rx(/^\d+/))));
  t('abc 123',
    [["abc","123"],""]);
  t('  AbC   1 REST',
   false);

  p = one(
    seq(trim(rx(/^[a-z]+/)),
        trim(rx(/^\d+/))));
  t('abc 123',
    [[["abc","123"]],""]);
  t('  abc   123   REST',
    [[["abc","123"]],"REST"]);
  t(' OTHER',
   false);

  p = zero_or_more(trim(rx(/^\d+/)));
  t('  REST',
    [[],"  REST"]);
  t('123  REST',
   [["123"],"REST"]);
  t('123 45 REST',
   [["123","45"],"REST"]);

  p =
    zero_or_more(seq(trim(rx(/^[a-z]+:/)),
                     trim(rx(/^\d+/))));
  t('  REST',
    [[], '  REST']);
  t('a: 123  REST',
    [[["a:","123"]],
     "REST"]);
  t('a: 123 b: 45 REST',
    [[["a:","123"],
      ["b:","45"]],
     "REST"]);

  p =
    one_or_more(
      with_keys(['key', 'val'],
                seq(trim(rx(/^[a-z]+/)),
                    trim(rx(/^\d+/)))));
  t('  REST',
    false);
  t('abc 123  REST',
    [[{"key":"abc","val":"123"}],
     "REST"]);
  t(' abc 123 xyz 45REST',
    [[{"key":"abc","val":"123"},
      {"key":"xyz","val":"45"}],
     "REST"]);

  //////////////////////////////

  function with_type(t, p) {
    return pc.describe(
      'with_type',
      [t, p],
      when(p,
           function (pat, inp) {
             return {type: t,
                     pat: pat};
           }));
  }

  var col        = trim(rx(/^([a-z0-9_]+):/i))
  var pat_quote  = trim(rx(/^"((\\"|[^"])*)"/))
  var pat_rx     = trim(rx(/^\/((\\\/|[^/])*)\//))
  var pat_word   = rx(/^\s*(\S+)/)
  var pat        = alt(with_type('quote', pat_quote),
                       with_type('rx',    pat_rx),
                       with_type('word',  pat_word));
  var col_pat    = with_keys(['col', 'pat'],
                             seq(col, pat));
  var bare_pat  =
      when(trim(pat_word),
           function (pat, inp) {
             return {col: "*",
                     pat: pat};
           });
  p = all(one_or_more(alt(col_pat, bare_pat)));

  t(' ',
    false);

  t(' word1  word2 123  ',
    [[{"col":"*", "pat":{"type":"word","val":"word1"}},
      {"col":"*", "pat":{"type":"word","val":"word2"}},
      {"col":"*", "pat":{"type":"word","val":"123"}}],
     ""]
   );

  t('word:123',
    [[{"col":"word",
       "pat":{"type":
            "word",
            "val":"123"}}],
     ""]);
  t('  quote:  "quoted \\" string"  ',
    [[{"col":"quote",
       "pat":{"type":"quote",
            "val":"quoted \\\" string"}}],
     ""]);
  t('rx:/a? \\/+regex*/',
    [[{"col":"rx",
       "pat":{"type":"rx",
            "val":"a? \\/+regex*"}}],""]);

  r =
    t(' this:"q. \\"ed" word1  that:word2 123.5 other: /regex\\? */ ',
      [[{"col":"this",
         "pat":{"type":"quote",
                "val":"q. \\\"ed"}},
        {"col":"*",
         "pat":{"type":"word",
                "val":"word1"}},
        {"col":"that",
         "pat":{"type":"word",
                "val":"word2"}},
        {"col":"*",
         "pat":{"type":"word",
                "val":"123.5"}},
        {"col":"other",
         "pat":{"type":"rx",
                "val":"regex\\? *"}}],
       ""]
     );
  var col_pats = r[0];
  var is_bare_pat = x => x.col === '*';

  console.log("%s", JSON.stringify(col_pats, null, 2));
  col_pats.
    filter(x => x.pat.type == 'rx').
    forEach(x => x.pat.rx_str = x.pat.val);
  col_pats.
    filter(x => x.pat.type == 'word').
    forEach(x => x.pat.rx_str = escape_regexp(x.pat.val));
  col_pats.
    filter(x => x.pat.type == 'quote').
    forEach(function(x) {
      x.pat.val = x.pat.val.replace(/\\"/g, '"');
      x.pat.rx_str = '^' + escape_regexp(x.pat.val) + '$';
    });

  bare_pats_rx_str =
    col_pats.
    filter(is_bare_pat).
    map(x => x.pat.rx_str).
    join('.+')
  col_pats = col_pats.filter(x => ! is_bare_pat(x))
  if ( bare_pats_rx_str !== '' ) {
    col_pats.push({col: "*",
                   pat: {type: 'rx',
                         val: bare_pats_rx_str,
                         rx_str: bare_pats_rx_str}})
  }
  console.log("%s", JSON.stringify(col_pats, null, 2));
}
