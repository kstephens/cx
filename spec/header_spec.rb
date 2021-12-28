require 'cx/header'

module CX
  RSpec.describe Header do
    subject { Header.new([:a, :b, :c]) }
    
    describe "new" do
      it "()" do
        h = Header.new
        expect(h.size) .to eq 0
        expect(h.map(&:to_s)) .to eq []
      end
      
      it "(n)" do
        h = Header.new(5)
        expect(h.size) .to eq 5
        expect(h.map(&:to_s)) .to eq %w(_COL_1 _COL_2 _COL_3 _COL_4 _COL_5)
        expect(h.map(&:to_sym)) .to eq [:_COL_1, :_COL_2, :_COL_3, :_COL_4, :_COL_5]
      end
      
      it "([...])" do
        h = Header.new(["a", "b"])
        expect(h.size) .to eq 2
        expect(h.map(&:to_s)) .to eq ["a", "b"]
      end
    end

    describe "[]" do
      it "Symbol" do
        expect(subject[:b].to_sym) .to eq :b
      end
      it "String" do
        expect(subject["c"].to_sym) .to eq :c
      end
      it "Integer" do
        expect(subject[2].to_sym) .to eq :c
        expect(subject[-1].to_sym) .to eq :c
      end
    end
    
    describe "alias!" do
      it "to resolve" do
        expect(subject.get(:f)) .to eq nil
        expect(subject.alias!(:b, :f)) .to eq subject
        expect(subject[:f].to_sym) .to eq :b
        expect(subject.get("f").to_sym) .to eq :b
        
        subject.alias!(:a, "g")
        expect(subject[:g].to_sym) .to eq :a
      end
    end

    describe "change_name!" do
      it "renames" do
        expect(subject.map(&:to_s)) .to eq %w(a b c)

        subject[:a].name = :f
        expect(subject.map(&:to_s)) .to eq %w(f b c)
      end

      it "does not allow collisions" do
        expect { subject[:a].name = :c } .to raise_exception
      end
    end

    describe "change_order!" do
      it "reorders" do
        cols = subject.columns.dup

        expect(subject.map(&:order)) .to eq [0, 1, 2]
        expect(subject.ordered.map(&:to_s)) .to eq %w(a b c)

        subject[:a].order = (subject[:b].order + subject[:c].order) * 0.5

        expect(cols.map(&:order)) .to eq [1.5, 1, 3]
        expect(subject.map(&:to_s)) .to eq %w(a b c)
        expect(subject.ordered.map(&:to_s)) .to eq %w(b a c)
      end
    end
    
    describe "<<" do
      it "simple case" do
        subject << :d
        expect(subject.map(&:to_s)) .to eq %w(a b c d)
        subject << "e"
        expect(subject.map(&:to_s)) .to eq %w(a b c d e)
      end
      
      it "renames on collision" do
        subject << :c
        expect(subject.map(&:to_s)) .to eq %w(a b c c4)
      end
    end
  end
end
