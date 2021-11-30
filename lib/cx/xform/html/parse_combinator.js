function nocache(module) {
  require("fs")
    .watchFile(require("path").resolve(module),
               () => {
                 delete require.cache[require.resolve(module)]});
}

var parcomb
  = (
    function () {
      function description(x) {
        return x === undefined ? 'null' : x.description || x + '';
      }
      function named(s, p) {
        p.description = s;
        return p;
      }
      function describe(s, args, p) {
        return named(s + '(' + args.map(description).join(', ') + ')', p);
      }
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

      function matched(m) {
        return m === false || m[1] === '' ? false : m;
      }

      //////////////////////////////////////
      
      function alt() {
        var ps = Array.from(arguments);
        return describe(
          'alt',
          ps,
          function (inp) {
            for ( var i = 0; i < ps.length; ++ i ) {
              var p = ps[i];
              if ( matched(m = p(inp)) ) {
                return m;
              }
            }
            return false;
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
            return inp === str ? [ s, '' ] : false;
          });
      }
      function rx(re) {
        return describe(
          'rx',
          [re],
          function (inp) {
            var m = inp.match(re);
            return m ? [ m[0], inp.substring(m.index + m[0].length) ] : false;
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
      // Positional binding.

      function with_keys(ns, p) {
        return describe(
          'with_names',
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
      
      ///////////////
      //
      function run_tests() {
        function t(p, inp, expected) {
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
        var p;
        
        p = alt(rx(/^[a-z]+/i), rx(/^\d+/));
        t(p, 'abc REST',
         ["abc"," REST"]);
        t(p, '1 REST',
         ["1"," REST"]);
        t(p, ' 1 REST',
         false);

        p = seq(rx(/^[a-z]+/i), rx(/^\d+/));
        t(p, 'abc REST',
         false);
        t(p, 'abc 123 REST',
         false);
        t(p, 'abc123 REST',
         [["abc","123"]," REST"]);

        p = seq(trim(rx(/^[a-z]+/i)), trim(rx(/^\d+/)));
        t(p, 'abc 123  REST',
         [["abc","123"],"REST"]);
        t(p, '  AbC   1 REST',
         [["AbC","1"], "REST"]);

        p = zero_or_more(trim(rx(/^\d+/)));
        t(p, '  REST',
          [[],"  REST"]);
        t(p, '123  REST',
         [["123"],"REST"]);
        t(p, '123 45 REST',
         [["123","45"],"REST"]);

        p = zero_or_more(seq(trim(rx(/^[a-z]+:/)),
                             trim(rx(/^\d+/))));
        t(p, '  REST',
          [[], '  REST']);
        t(p, 'a: 123  REST',
          [[["a:","123"]],
           "REST"]);
        t(p, 'a: 123 b: 45 REST',
          [[["a:","123"],
            ["b:","45"]],
           "REST"]);

        p =
          one_or_more(
            with_keys(['key', 'val'],
                      seq(trim(rx(/^[a-z]+/i)),
                          trim(rx(/^\d+/)))));
        t(p, '  REST',
          false);
        t(p, 'abc 123  REST',
          [[{"key":"abc","val":"123"}],
           "REST"]);
        t(p, ' abc 123 xyz 45REST',
          [[{"key":"abc","val":"123"},
            {"key":"xyz","val":"45"}],
           "REST"]);
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
