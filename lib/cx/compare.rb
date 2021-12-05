require 'cx'

module CX
  module Compare
    def self.compare a, b
      case 
      when a.nil?
        -1
      when b.nil?
        1
      when a.equals?(b)
        0
      else
        a <=> b
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
