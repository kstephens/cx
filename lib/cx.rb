require "cx/version"

module CX
  def self.base_dir ; BASE_DIR ; end
  BASE_DIR = File.expand_path('../..', __FILE__)
  def self.supress_warnings new_flags = nil
    save = $VERBOSE
    begin
      $VERBOSE = new_flags
      yield
    ensure
      $VERBOSE = save
    end
  end
  Empty_Hash   = { }.freeze
  Empty_Array  = [].freeze
  Empty_String = "".freeze
end

begin
  RubyVM::InstructionSequence.compile_option =
    {
      tailcall_optimization: true,
      trace_instruction: false,
    }
rescue
end if (ENV['CX_TCO'] || 1).to_i > 0

require 'cx/support'

