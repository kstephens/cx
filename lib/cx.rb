require "cx/version"

module CX
  class Error < StandardError; end
  def self.base_dir ; BASE_DIR ; end
  BASE_DIR = File.expand_path('../..', __FILE__)
end
