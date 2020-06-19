require 'cx'
require 'cx/pipe'
require 'cx/csv_safe'

module CX
  class CSVIn < Pipe
  include Pipe::Parse
  include CSVSafe
  register! :'-csv',
  'parse CSV lines'
  # TODO: Potentially refactor into a IOLines base class.
  def call input, env
    i = 0
    input.map! do |e|
      i += 1
      e = e.strip
      csv_parse_line(e, i) unless e.empty?
    end.compact!
    app.call(input, env)
  end
end

class CSVOut < Pipe
  include CSVSafe, Pipe::Format
  register! :'csv-',
  'emit CSV rows'
  # TODO: Potentially refactor into a IOLines base class.
  def call input, env
    i = -1
    input.map!{ |e| csv_generate_line(e, (i += 1)) }
    app.call(input, env)
  end
end
end
