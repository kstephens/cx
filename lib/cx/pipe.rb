require 'cx'

module CX
  # Base class for standard Pipe applications.
# Initialization protocol is defined in Main::make_cmd.
class Pipe
  include Enumerable, Logging, PPSafe
  extend Logging
  
  attr_accessor :app, :args, :opts, :identifier, :block

  def initialize app = nil, args = nil, opts = nil, &block
    @app   = app  || lambda{|input, env| input}
    @args  = args || [ ]
    @opts  = opts || { }
    @block = block
    init_more!
    self
  end
  def init_more! ; self ; end
  
  #################################

  def run! env
    call(new_table, env)
  end

  def new_table input = Table, *args
    input.new(*args).tap{|t| t.identifier = "#{inspect :shallow}"}
  end
  
  def call input, env
    raise_ "call : unimplemented"
  end

  #################################

  def inspect mode = nil
    oid = identifier || "#{'%x' % object_id}"
    x = inspect_pipe(mode).strip
    x &&= " #{x.strip}"
    case mode
    when :basic, nil
      "#<#{self.class.name} #{oid}#{x} app=#{app && app.inspect}>"
    when :shallow
      "#<#{self.class.name} #{oid}#{x} #{app && "..."}>"
    else
      raise "invalid inspect mode : #{mode.inspect}"
    end
  end
  def inspect_pipe mode = nil
    ""
  end

  #################################
  
  def self.factory name
    FACTORY[name] or raise_ "command #{name.inspect} is unregistered"
  end
  FACTORY = { }
  def self.register! name_and_aliases, synopsis = "", options = { }
    name, *aliases = name_and_aliases
    COMMANDS[name] = { class: self, name: name, aliases: aliases, synopsis: synopsis, options: options}
    ([ name ] + aliases).each{|n| FACTORY[n] = self}
    self
  end
  COMMANDS = { }

  module In       ; end
  module Out      ; end
  module Parse    ; end
  module Format ; end
  module Process ; end
  module Diagnostic ; end
  module NeedsHeader ; end
  module Pipeline ; end

  module ColumnsFromArgs
    attr_accessor :columns
    def init_more!
      super
      if String === (cols = opts[:C] || opts[:columns])
        cols = [ cols ]
      else
        cols = args
      end
      @columns = Header.parse_column_args(cols)
    end
  end
end
end
