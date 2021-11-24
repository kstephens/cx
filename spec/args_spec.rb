require 'cx/args'

module CX
  RSpec.describe Args do
    subject() { Args.new.parse!(input, opts) }
    let(:opts) { {} }
    let(:input) { "--f --a-opt=abc --no-b a -- b --not-an-option".split(' ') }
    
    describe "basic" do
      it "parses" do
        expect(subject.opts) .to eq({:f=>true, :a_opt=>"abc", :b=>false})
        expect(subject.args) .to eq ["a", "b", "--not-an-option"]
        expect(subject.argv) .to eq ["--f", "--a-opt=abc", "--no-b", "a", "--", "b", "--not-an-option"]
        expect(input) .to eq([])
      end
    end

    describe "no_args: true" do
      let(:opts) { {no_args: true} }
      it "stops at first non-option" do
        expect(subject.opts) .to eq({:f=>true, :a_opt=>"abc", :b=>false})
        expect(subject.args) .to eq []
        expect(subject.argv) .to eq ["--f", "--a-opt=abc", "--no-b" ]
        expect(input) .to eq ["a", "--", "b", "--not-an-option"]
      end
    end

    describe "non-strings" do
      let(:input) { ['--f', '--a=123', 'a', '--', :NOT_A_STRING, 'b'] }
      it "parses" do
        expect(subject.opts) .to eq({:f=>true, :a=>"123"})
        expect(subject.args) .to eq ["a", :NOT_A_STRING, "b"]
        expect(subject.argv) .to eq ["--f", "--a=123", "a", "--", :NOT_A_STRING, "b"]
        expect(input) .to eq([])
      end
    end

    describe "terminator: Proc" do
      let(:input) { "--f --a=abc --no-b a -- b --not-an-option DELIMITER c d e".split(' ') }
      let(:opts) { {terminator: Proc.new{|arg| arg == 'DELIMITER'}} }
      it "parses" do
        expect(subject.opts) .to eq({:f=>true, :a=>"abc", :b=>false})
        expect(subject.args) .to eq ["a", "b", "--not-an-option"]
        expect(subject.argv) .to eq ["--f", "--a=abc", "--no-b", "a", "--", "b", "--not-an-option"]
        expect(input) .to eq ["DELIMITER", "c", "d", "e"]
      end
    end
  end
end
