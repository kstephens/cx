require 'cx/util'

module CX
  RSpec.describe Rx do
    subject { Object.new.extend(Rx) }
    describe "glob_to_rx" do
      def fut str, *args
        subject.glob_to_rx(str, *args)
      end 
      it "converts" do
        expect(fut "") .to eq("")
        expect(fut "a") .to eq("a")
        expect(fut "a1 b2") .to eq("a1 b2")
        expect(fut "ab.c") .to eq("ab\\.c")
        expect(fut "ab*c") .to eq("ab.*c")
        expect(fut "ab?c") .to eq("ab.c")
        expect(fut "ab\nc") .to eq("ab\nc")
        expect(fut "ab\\nc") .to eq("ab\\nc")
        expect(fut "ab\\\\c") .to eq("ab\\\\c")

        expect(fut "ab|c") .to eq("ab\\|c")
        expect(fut "ab{c") .to eq("ab\\{c")
        expect(fut "ab}c") .to eq("ab\\}c")
        expect(fut "ab(c") .to eq("ab\\(c")
        expect(fut "ab)c") .to eq("ab\\)c")
        expect(fut "ab^c") .to eq("ab\\^c")
        expect(fut "ab$c") .to eq("ab\\$c")

        expect(fut "ab**c") .to eq("ab.*c")
        expect(fut "ab**c", file: true) .to eq("ab.*c")
        expect(fut "ab*c", file: true) .to eq("ab[^/]*c")
        expect(fut "ab?*c", file: true) .to eq("ab[^/][^/]*c")
      end
    end
  end
end
