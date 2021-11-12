require 'cx/column_args'

module CX
  RSpec.describe ColumnArgs do
    subject() { ColumnArgs.new.parse!(argv) }
    let(:argv) do
      [
        "a",
        "b:",
        "c:!",
        "d:-",
        "e:+",
        "f:x;y=z;q",
        "g:!;asdf",
        "12:x=z",
      ]
    end
    it "parses" do
      expect(subject.map(&:name))
        .to eq([:a, :b, :c, :d, :e, :f, :g, nil])
      expect(subject.map(&:index))
        .to eq([nil, nil, nil, nil, nil, nil, nil, 11])
      expect(subject.map(&:opts))
        .to eq([{}, {}, {:negate=>true}, {:order=>-1}, {:order=>1}, {:y=>"z"}, {:negate=>true}, {:x=>"z"}])
      expect(subject.map(&:args))
        .to eq([[], [], [], [], [], ["x", "q"], ["asdf"], []])
      expect(subject.map(&:arg_str))
        .to eq(argv)
      expect(subject.map(&:rest_str))
        .to eq(["", "", "!", "-", "+", "x;y=z;q", "!;asdf", "x=z"])
    end
  end
end
