require 'cx/command_factory'

module CX
  RSpec.describe CommandFactory do
    subject() { CommandFactory.new }
    it "build!" do
      subject.build_index!
    end
    it "load!" do
      subject.load!
    end
  end
end
