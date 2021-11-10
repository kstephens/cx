require 'cx/pipeline_builder'

module CX
  RSpec.describe PipelineBuilder do
    subject() { PipelineBuilder.new.parse!(argv) }
    let(:argv) {
      "--gflg --gopt=abc124 cmd1 // cmd2 --flg2 arg2 // // cmd3 --flg3 --opt3=abc123 arg3 arg3".split(' ')
    }
    it "parses" do
      expect(subject.argv) .to eq(argv)
      expect(subject.global.opts) .to eq({:gflg=>true, :gopt=>"abc124"})
      expect(subject.global.args) .to eq([])
      expect(subject.commands.map(&:to_h))
        .to eq(
          [
            {:argv=>["cmd1"], :args=>["cmd1"], :opts=>{}},
            {:argv=>["cmd2", "--flg2", "arg2"],
              :args=>["cmd2", "arg2"],
              :opts=>{:flg2=>true}},
            {:argv=>["cmd3", "--flg3", "--opt3=abc123", "arg3", "arg3"],
              :args=>["cmd3", "arg3", "arg3"],
              :opts=>{:flg3=>true, :opt3=>"abc123"}}
          ]
        )
    end
  end
end
