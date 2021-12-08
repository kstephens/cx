require 'cx'

module CX
  module Random
    class << self
      attr_accessor :random, :seed, :use_seed
    end

    def self.init! x = nil
      self.use_seed = x || (ENV['CX_RANDOM_SEED'] || 0).to_i.nonzero?
      self.seed = use_seed && use_seed > 1 ? use_seed : 1638854222 # Arbitrary
      self.random = nil
    end
    init!
    
    def self.random
      @random ||=
        ::Random.new(use_seed ? seed : ::Random.new_seed)
    end

    def self.uuid
      if use_seed
        UUID_BYTES.map do |b|
          random.bytes(b).unpack('C*').map{|b| '%02x' % b} * ''
        end * '-'
      else
        @@securerandom ||= (require 'securerandom'; true)
        SecureRandom.uuid
      end
    end
    
    UUID_BYTES = # SecureRandom.uuid.split('-').map(&:size).map{|x| x / 2}
      [4, 2, 2, 2, 6]
  end
end
