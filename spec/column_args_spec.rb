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
        "*:foo",
      ]
    end
    
    it "parses" do
      expect(subject.map(&:name))
        .to eq([:a, :b, :c, :d, :e, :f, :g, nil, :*])
      expect(subject.map(&:index))
        .to eq([nil, nil, nil, nil, nil, nil, nil, 11, nil])
      expect(subject.map(&:opts))
        .to eq([{}, {}, {:negate=>true}, {:order=>-1}, {:order=>1}, {:y=>"z"}, {:negate=>true}, {:x=>"z"},
          {}])
      expect(subject.map(&:args))
        .to eq([[], [], [], [], [], ["x", "q"], ["asdf"], [], ["foo"]])
      expect(subject.map(&:arg_str))
        .to eq(argv)
      expect(subject.map(&:rest_str))
        .to eq(["", "", "!", "-", "+", "x;y=z;q", "!;asdf", "x=z", "foo"])
    end
    
    describe "bind!" do
      subject() { ColumnArgs.new.parse!(argv).bind!(header) }
      let(:header) { Header.new([:a, :b, :c, :d, :e, :f]) }
      let(:argv) do
        [
          "a",
          "*",
          "c:!",
          "4",
          "unknown:+",
        ]
      end
      
      it "binds" do
        expect(subject.map(&:name))
          .to eq([:a, :*, :c, nil, :unknown])
        expect(subject.map(&:index))
          .to eq([0, nil, 2, 3, nil])
        expect(subject.map(&:column).map(&:to_s))
          .to eq(["a", "", "c", "d", ""])
      end

      describe "unbound" do
        it "finds" do
          expect(subject.unbound.map(&:name))
            .to eq([:*, :unknown])
        end
      end

      describe "wildcards!" do
        subject() {
          ColumnArgs.new.parse!(argv).bind!(header).wildcards!
        }
        
        it "interpolates * as other columns" do
          expect(subject.map(&:name))
            .to eq([:a, :b, :e, :f, :c, nil, :unknown]) # nil: HUH?
          expect(subject.map(&:index))
            .to eq([0, 1, 4, 5, 2, 3, nil])
          expect(subject.map(&:column).map(&:to_s))
            .to eq(["a", "b", "e", "f", "c", "d", ""])
        end
        
        describe "unbound" do
          it "does not find *" do
            expect(subject.unbound.map(&:name))
              .to eq([ :unknown])
          end
        end
      end

    end
  end
end
