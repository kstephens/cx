function nocache(module) {
  require("fs")
    .watchFile(require("path").resolve(module),
               () => {
                 delete require.cache[require.resolve(module)]});
}

var parcomb
  = (
    function () {
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

      //////////////////////////////////////
      // Documentation:
      
      function description(x) {
        switch ( typeof x ) {
        case 'undefined':
          return'undefined';
        case 'number':
          return x + '';
        case 'string':
          return JSON.stringify(x);
        case 'function':
          return x.description || 'function(){...}';
        case 'object':
          return x.description = JSON.stringify(x);
        default:
          throw typeof(x);
        };
      }
      function named(s, p) {
        p.description = s;
        return p;
      }
      function describe(s, args, p) {
        return named(s + '(' + args.map(description).join(', ') + ')', p);
      }
      
      //////////////////////////////////////

      function matched(m) {
        return m === false ? false : m;
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
            return matched(m) && m[1] === '' ? m : false;
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
                f(m[0]),
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
        
        t(' this:"q ed" word1  that:word2 123  ',
          [[{"col":"this","pat":{"type":"quote","val":"q ed"}},
            {"col":"*","pat":{"type":"word","val":"word1"}},
            {"col":"that","pat":{"type":"word","val":"word2"}},
            {"col":"*","pat":{"type":"word","val":"123"}}],
           ""]
         );
        

      }
      run_tests();
      
      return
      {
        rx: rx
        // one_of: one_of,
        // one: one,
        // zero_or_more: zero_or_more,
        // one_or_more: one_or_more
      };
    })();
