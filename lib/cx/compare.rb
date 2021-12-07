require 'cx'

module CX
  module Compare
    include Logging
    
    def self.compare a, b
      # pp(compare: { a: a, b: b, equal?: a.equal?(b) })
      case 
      when a.nil?
        -1
      when b.nil?
        1
      when a.equal?(b)
        0
      else
        begin
          a <=> b
        rescue
          log.debug
          a.to_s <=> b.to_s
        end
      end
    rescue
      0
    end
  end

  module ::Boolean
    def <=> b
      if Boolean === b
        (self ? 1 : -1) <=> (b ? 1 : -1)
      else
        raise TypeError
      end
    end
  end
end
