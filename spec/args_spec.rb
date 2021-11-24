require 'cx/args'

module CX
  RSpec.describe Args do
    subject() { Args.new.parse!(argv) }
    describe "basic" do
      let(:argv) { "--flag --option=abc124 a -- b --not-an-option".split(' ') }
      it "parses" do
        expect(subject.argv) .to eq argv
        expect(subject.args) .to eq ["a", "b", "--not-an-option"]
        expect(subject.opts) .to eq({:flag=>true, :option=>"abc124"})
      end
    end
    describe "non-strings" do
      let(:argv) { ['--flag', '--option=abc124', 'a', :NOT_A_STRING, 'b'] }
      it "parses" do
        expect(subject.argv) .to eq argv
        expect(subject.args) .to eq ["a", :NOT_A_STRING, "b"]
        expect(subject.opts) .to eq({:flag=>true, :option=>"abc124"})
      end
    end
  end
end
