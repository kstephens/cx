require 'cx/column_args'

module CX
  RSpec.describe ColumnArgs do
    subject() { ColumnArgs.new.parse!(argv) }
    let(:header) { Header.new([:a, :b, :c, :d, :e, :f]) }
    let(:bound) { subject.bound }
    let(:argv) do
      [
        "a",
        "b:",
        "c:!",
        "d:-",
        "e:+",
        "f:x;y=z;q",
        "g:!;asdf",
        "2:x=z",
        "*:foo",
        "z",
        "12"
      ]
    end
    
    it "parses" do
      expect(subject.map(&:name))
        .to eq([:a, :b, :c, :d, :e, :f, :g, nil, :*, :z, nil])
      expect(subject.map(&:index))
        .to eq([nil, nil, nil, nil, nil, nil, nil, 2, nil, nil, 12])
      expect(subject.map(&:opts))
        .to eq([{}, {}, {:negate=>true}, {:order=>-1}, {:order=>1}, {:y=>"z"}, {:negate=>true}, {:x=>"z"},
          {}, {}, {}])
      expect(subject.map(&:args))
        .to eq([[], [], [], [], [], ["x", "q"], ["asdf"], [], ["foo"],
          [], []])
      expect(subject.map(&:arg_str))
        .to eq(argv)
      expect(subject.map(&:rest_str))
        .to eq(["", "", "!", "-", "+", "x;y=z;q", "!;asdf", "x=z", "foo",
          "", ""])
    end

    describe "find" do
      subject() { ColumnArgs.new.parse!(argv).bind!(header) }
      it "does not find invalid columns" do
        # pp bound: bound
        expect(subject.find(nil))
          .to eq(nil)
          expect(subject.find(nil, :bound))
          .to eq(nil)
        expect(subject.find(:*))
                    .to eq(nil)
                    expect(subject.find(:z))
                    .to eq(nil)
                    expect(subject.find(12))
                    .to eq(nil)
      end

      it "finds columns" do
        expect(subject.find(0).column)
        .to eq(header[:a])
        expect(subject.find(:a).column)
        .to eq(header[:a])
        expect(subject.find("a").column)
        .to eq(header[:a])

        expect(subject.find(-1).column)
        .to eq(header[:f])

        expect(subject.find(header[:c]).column)
        .to eq(header[:c])
      end
    end
    
    describe "bind!" do
      subject() { ColumnArgs.new.parse!(argv).bind!(header) }
      let(:argv) do
        [
          "a",
          "*",
          "c:!",
          "4",
          "-1",
          "unknown:+",
        ]
      end
      
      it "binds" do
        expect(subject.map(&:name))
          .to eq([:a, :*, :c, nil, nil, :unknown])
        expect(subject.map(&:index))
          .to eq([0, nil, 2, 3, 5, nil])
        expect(subject.map(&:column).map(&:to_s))
          .to eq(["a", "", "c", "d", "f", ""])
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
            .to eq([:a, :b, :e, :c, nil, nil, :unknown]) # nil: HUH?
          expect(subject.map(&:index))
            .to eq([0, 1, 4, 2, 3, 5, nil])
          expect(subject.map(&:column).map(&:to_s))
            .to eq(["a", "b", "e", "c", "d", "f", ""])
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
