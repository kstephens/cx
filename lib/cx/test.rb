# frozen_string_literal: true

require 'cx'
require 'cx/table'
require 'cx/xform/header'
require 'cx/xform/pipeline'
require 'stringio'
require 'pp'

module CX
  module Test
    class << self
      attr_accessor :metadata
    end
    
    def make_table size = 100
      ints = (-100  .. 100).to_a
      strs = ("aaa" .. "zzz").to_a
      vals = (1 .. 200).map{|x| "#{x}%"}
      rand = Random.new(12345678)
      header = Header.new([:id, :a, :b, :b, :"X %"])
      table = Table.new([], header)
      header[:id].meta.type = ::Integer
      header[:"X %"].meta.type = ::Numeric
      size.times do | i |
        table << [
          i + 1001,
          ints.sample(random: rand),
          (i % 3).zero? ? strs.sample(random: rand) + " " : strs.sample(random: rand),
          (i % 5).zero? ? nil : i / 2.5,
          vals.sample(random: rand),
        ].map(&:to_s)
      end
      table
    end

    def build cls, *argv
      cls.new.build argv
    end
    
    def run_pipeline pipeline, opts = {}
      opts[:env] ||= {}
      table = nil
      
      out = StringIO.new
      output_format = opts[:output_format] || (Xform::Pipeline.new | Xform::HeaderOut | Xform::CsvOut)
      input_pipeline = Xform::Pipeline.new

      case
      when opts[:input_data]
        File.write("tmp/last-pipeline.input", opts[:input_data])

        input_format = opts[:input_format] || Xform::CsvIn
        input_io = StringIO.new(opts[:input_data])

        input_pipeline =
          Xform::Pipeline.new |
          build(Xform::IoIn, input_io) |
          input_format
      when opts[:table]
        table = opts[:table]
      else
        table = make_table(opts[:size] || 10)
      end

      pipeline =
        input_pipeline |
        Xform::MetaIn |
        (pipeline || Xform::Pipeline.new) |
        output_format |
        build(Xform::IoOut, out)
      pipeline.call(table, opts[:env])
      out.string
    end

    def assert_pipeline pipeline, *args
      # pp([:assert_pipeline, :args, args])
      expected = opts = nil
      case args.map(&:class)
      when [String, Hash]
        expected, opts = args
      when [String]
        expected = args.first
      when [Hash]
        opts = args.first
      else
        raise ArgumentError, args.inspect
      end
      opts ||= { }
      
      actual = run_pipeline(pipeline, opts || {})
      actual = actual.
        sub(/\A/, '|').
        gsub(/\n/, "|\n|").
        sub(/\|\Z/, '')

      if expected
        if actual != expected
          File.write("tmp/last-pipeline.actual", actual)
          # File.write("/dev/tty", pipeline.inspect(:no_id))
          # exit!
          puts <<"END"
#### Actual : #{Test.metadata[:full_description]}
####
#{actual}
####
END
        end
        expect(actual) .to eq(expected)
      else
        assert_content actual, opts[:test_name]
        # puts actual
        # binding.pry
      end
      actual
    end

    def assert_content actual_content, name = nil
      unless name
        m = Test.metadata
        name =
          m[:file_path].
          sub(%r{^\./spec/}, '').
          sub(/\.rb$/, '') +
          '/' +
          m[:full_description]
        name = name.gsub(/ +/, '-').gsub(%r{[^-_/a-z0-9]}i, '_')
        if false
          # File.write("/dev/tty", x.metadata.inspect)
          File.write("/dev/tty", name.inspect)
          exit! 9
        end
      end
      
      unless String === actual_content
        strio = StringIO.new
        PP.pp(actual_content, strio, 250)
        actual_content = strio.string
      end

      dir = "spec/#{name}"
      expected_file = "#{dir}.expected"
      actual_file   = "#{dir}.actual"
      diff_file     = "#{dir}.diff"
      expected_content = File.read(expected_file) rescue nil

      if false
        puts "expected_content ::::\n#{expected_content}\n::::"
        puts "actual_content   ::::\n#{actual_content}\n::::"
        puts "expected_file    = #{expected_file}"
        puts "actual_file      = #{actual_file}"
      end
      
      if actual_content != expected_content
        FileUtils.mkdir_p(File.dirname(expected_file))
        File.write(expected_file, "") unless expected_content
        File.write(actual_file, actual_content)
        Kernel.system("set -x; diff -u '#{expected_file}' '#{actual_file}' > '#{diff_file}'")
        Kernel.system("cat '#{diff_file}' | (colordiff 2>/dev/null || cat -)")
        # puts File.read(diff_file)

        if accept = accept_diff(name)
          File.write(expected_file, actual_content)
          File.unlink(actual_file)
          File.unlink(diff_file)
        else
          File.write("/dev/tty", <<END)
#################################################################
##
## assert_content : #{name}
## expected_file  : #{expected_file}"
## actual_file    : #{actual_file}"
##
##  if $CX_TEST_ACCEPT is:
##    * 'prompt'       - prompts for Y.
##    * 'all'          - accept the diff.
##    * 'match=REGEX'  - accept if the name matches REGEX.
##
#################################################################
END
          expect(actual_file) .to eq(expected_file)
        end
      end
      
    rescue => exe
      pp(exe)
      pp(exe.backtrace)
      # binding.pry
      raise exe
    end

    def accept_diff name
      accept = prompt = false
      (ENV['CX_TEST_ACCEPT'] || '').split(',').each do | opt |
        accept ||=
          case opt
          when /^prompt$/i
            prompt = true
          when /^all$/i
            true
          when /^match=(.+)$/
            name =~ /#{$1}/
          end
      end
      if ! accept && prompt && (prompt = prompt_user("#{name} diff : Accept? [AY]: "))
        accept = prompt =~ /^[ay]/i
      end
      accept
    end
    
    def prompt_user msg, default = nil
      File.open("/dev/tty", "w+") do | tty |
        tty.write "  ### #{msg} : "
        tty.readline rescue default
      end
    end

    def assert_many actual, expected
      unless expected == actual
        msg = "actual = \n" + 
          PP.pp(actual, '', 200)
        # puts msg
        File.write("spec/assert_many.actual", msg)
        expect(actual) .to eq(expected)
      end
      actual
    end
    
    def stringify v
      case v
      when Time
        v.iso8601(3)
      else
        v.to_s
      end
    end

    extend self
  end
end
