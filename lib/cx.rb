require "cx/version"

module CX
  class Error < StandardError; end
  def self.base_dir ; BASE_DIR ; end
  BASE_DIR = File.expand_path('../..', __FILE__)
end

begin
  RubyVM::InstructionSequence.compile_option =
    {
      tailcall_optimization: true,
      trace_instruction: false,
    }
rescue
end

