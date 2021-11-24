require 'cx/pipeline_builder'

module CX
  RSpec.describe PipelineBuilder do
    subject() { PipelineBuilder.new.parse!(argv) }
    describe 'basic pipeline' do
      let(:argv) do
        "--gflg --gopt=abc124 cmd1 // cmd2 --flg2 arg2 // // cmd3 --flg3 --opt3=abc123 arg3 arg3".split(' ')
      end
      it "parses" do
        # expect(argv) .to eq([])
        expect(subject.global.opts) .to eq({:gflg=>true, :gopt=>"abc124"})
        expect(subject.global.args) .to eq([])
        expect(subject.pipeline.commands.map(&:args).map(&:to_h))
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
    describe "complex pipeline" do
      let(:argv) do
        "--gflg p1-c1 // p1-c2 --o1=123 {{ --p2-opt=345 p2-c1 --f1 // p2-c3 --o2=234 }} p1-c2-a2 // // p1-c3".split(' ')
      end
      it "parses" do
        # expect(argv) .to eq([])
        expect(subject.global.opts) .to eq({:gflg=>true})
        expect(subject.pipeline.args.opts) .to eq({:gflg=>true})
        expect(subject.global.args) .to eq([])

        cmds = subject.pipeline.commands
        expect(cmds.map(&:class)).
          to eq([
            CX::PipelineBuilder::Command,
            CX::PipelineBuilder::Command,
            CX::PipelineBuilder::Command,
          ])
        
        expect(cmds[0].args.to_h).
          to eq({
            :args=>["p1-c1"],
            :argv=>["p1-c1"],
            :opts=>{}})
        
        expect(cmds[1].args.args.map(&:class)).
          to eq([String, CX::PipelineBuilder::Pipeline, String])
        
        expect(cmds[1].args.args[0]).
          to eq("p1-c2")

        expect(cmds[1].args.args[1].args.args).
          to eq([])
        expect(cmds[1].args.args[1].args.opts).
          to eq({:p2_opt=>"345"})
         
        expect(cmds[1].args.args[1].commands.map(&:args).map(&:to_h)).
          to eq([
            {:args=>["p2-c1"],
              :argv=>["p2-c1", "--f1"],
              :opts=>{:f1=>true}
            },
            {:args=>["p2-c3"],
              :argv=>["p2-c3", "--o2=234"],
              :opts=>{:o2=>"234"}
            }])
        
        expect(cmds[1].args.args[2]).
          to eq("p1-c2-a2")
        
        expect(cmds[2].args.to_h).
          to eq({
            :args=>["p1-c3"],
            :argv=>["p1-c3"],
            :opts=>{}})
      end
      
      it "builds xform" do
        subject.factory = lambda do | args |
          args
        end
        actual = subject.build_xform
        # pp(actual: actual)
      end
    end
  end
end
