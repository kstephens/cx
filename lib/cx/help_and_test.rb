# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'fileutils'

module CX
  class Main
  def unit_test!
    [
      # {"" => []},
      {"in" =>
       [[:in, [], {}]]},
      {"in foo" =>
       [[:in, ["foo"], {}]]},
      {"in --a=1 --b baz" =>
       [[:in, ["baz"], {a: "1", b: 1}]]},
      {"in --a=1 foo // out bar" =>
       [[:in,  ["foo"], {a: "1"}],
        [:out, ["bar"], {}]]},
      {"in foo {{ a // b }}" =>
       [[:in, ["foo", [
                 [:a, [], {}],
                 [:b, [], {}]]
              ], {}]]},
      {"in --a foo {{ a --b=2 // b --c }} // out bar" =>
       [[:in, ["foo", [
                 [:a, [], {b: "2"}],
                 [:b, [], {c: 1}]]],
         {a: 1}],
        [:out, ["bar"], {}]]},
    ].each do | x |
      cmd_line, expected = x.keys.first, x.values.first
      cmd_args = Shellwords.split(cmd_line)
      # pp(cmd_line: cmd_line, cmd_args: cmd_args); binding.pry
      actual = parse_pipeline! cmd_args
      assert_eq! expected, actual        , cmd_line
      assert_eq! 0,        cmd_args.size , cmd_line
    end
    
    result = make_cmd :app, [:in, ["arg1"], {opt: "opt"}]
    assert_eq!(IOIn,          result.class)
    assert_eq!(:app,          result.app)
    assert_eq!(["arg1"],      result.args)
    assert_eq!({opt: "opt"},  result.opts)

    self
  end

  def assert_eq! expected, actual, msg = nil
    line = caller[0].sub(/:in.*/, '')
    result = expected == actual
    
    msg = <<"END"
#{msg} :
  expected: #{expected.inspect}
  actual:   #{actual.inspect}
  line:     #{line}"
END
    msg = (result ? "OK:    " : "FAIL: ") + msg
    if ! result && opts[:break]
      puts msg + "\n"
      binding.pry
    end
    raise_ msg unless result
    puts   msg
    result
  end
    end
    

  class HelpAndTest
  def self.examples
    @@examples ||=
      begin
        d = File.read(CX.base_dir + "/lib/cx/examples.txt")
        d.freeze
      end
  end
  def self.test! opts = { }
    exit! new.run!(opts)
  end
  
  def run! opts = {}
    progname = 'cx2'
    ENV["CX_OPTS"] = '--verbose'
    ENV["SHELL"]   = '/bin/bash' # ??? does not affect #system
    # Macports
    ENV['PATH'] = ['/opt/local/libexec/gnubin', ENV['PATH']] * ':'
 
    test_dir = "tmp/cx.test"
    FileUtils.mkdir_p test_dir or raise
    Dir.chdir test_dir or raise

    examples = self.class.examples

    File.write(help_expect = "cx.examples.expect", examples)
    help_output = "cx.examples.output"
    help_out = File.open(help_output, "w")

    groups = examples.
               gsub(/(\n\n+)(\s+[\$\#])/){|m| $1 + "\001" + $2}.
               split("\001", -1).
               map{ |g| g.split("\n", -1).
                      each{ |l| l << "\n" }}
    results = [ ]    
    i = -1
    while group = @group = groups.shift
      group_ = group.map(&:dup)
      i += 1
      output_file = "test.#{i}.output"
      expect_file = "test.#{i}.expect"
      diff_file   = "test.#{i}.diff"
      input_file  = nil
      group << "\n"
      comments = [ ]
      while head = group.shift
        help_out << head
        case head
        when /^\s*$/
        when /^\s+\#/
          comments << head
        when %r{^\s+\$\s+cat\s+\<\<END\s+\>\s*(\S+)$}
          input_file = $1.strip
          input = take_until("END\n") * ''
          File.write(input_file, input)
          input += take_until(nil) * '' 
          help_out << (help = String.new << input)
        when %r{^((\s+\$\s+)(.*))$}
          line, prefix, cmd = $1 + "\n", $2, $3
          group.pop == "\n" or raise
          group.pop == "\n" or raise
          expect = take_until(nil)
          expect.pop
          expect = [ *comments, line, *expect ]
          expect = expect * ''
          File.write(expect_file, expect)

          name = "\##{i} : #{cmd}"
          puts "  --  #{name}"
          system "(#{cmd}) > '#{output_file}' 2>&1"
          output = File.readlines(output_file)
          
          output = [ *comments, line, output ] * ''
          File.write(output_file, output)

          help_out << (help = output)

          status = diff! name, expect_file, output_file, diff_file
          results << [name, status]

          comments = [ ]
          $stdout.puts "  => #{status} "
          unless status == :OK
            pp(group: group_)
            if opts[:_break___]
              binding.pry
              exit!
            end
          end
        else
          raise "unexpected line #{head.inspect}"
        end
      end
    end

    help_out.close

    errors = results.select{|x| x[1] != :OK}.map(&:first)

    pp(results: results)
    pp(errors: errors)
    errors.size
  rescue => exc
    pp(exc: exc, bt: exc.backtrace)
    raise
  ensure
    help_out.close rescue nil
  end

  def diff! name, expect_file, output_file, diff_file
    diff_cmd = "diff -u '#{expect_file}' '#{output_file}' > '#{diff_file}' 2>&1" 
    system diff_cmd

    diff_result = File.read(diff_file)

    status = diff_result.empty? ? :OK : :FAILED
    return status if status == :OK
    puts <<"END"
#############
  name:   #{name}
  status: #{status}
  diff:   #{diff_cmd}
  expect:
  =========
#{File.read(expect_file)}  =========
  output: 
  =========
#{File.read(output_file)}  =========
  diff:
  =========
#{diff_result}=========
#############
END
    status
  end
  
  def take_until p, lines = @group
    p = pred(p)
    result = []
    while line = lines.first and ! p.call(line)
      line = lines.shift
      result << line
    end
    result
  end
  def pred p
    case p
    when Proc
      p
    when Symbol
      lambda{ |x| x.send(p) } 
    when Regexp
      lambda{|x| p.match(x)}
    else
      lambda{ |x| p == x }
    end
  end
end
end
