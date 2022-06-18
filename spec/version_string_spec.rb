require 'cx/version_string'
require 'terminal-table'

module CX
  RSpec.describe VersionString do
    subject { VersionString }
    let(:examples) { [ "" ] + %w[ 1 2 1.2 1.2.1 1.23a 1.23-b ] + ["a 2.3", "a 2.4", "b", "b 1.1"]}
    let(:versions) { examples.map{|e| subject[e]} }
    def table rows
      Terminal::Table.new(rows: examples.map(&:inspect).zip(rows.map(&:inspect)))
      .to_s.tap{|s| puts s if false }
    end

    it "strs" do
      expect(table(versions.map(&:strs)))
        .to eq(<<~END.strip)
        +----------+----------------------------+
        | ""       | []                         |
        | "1"      | ["1"]                      |
        | "2"      | ["2"]                      |
        | "1.2"    | ["1", ".", "2"]            |
        | "1.2.1"  | ["1", ".", "2", ".", "1"]  |
        | "1.23a"  | ["1", ".", "23", "a"]      |
        | "1.23-b" | ["1", ".", "23", "-", "b"] |
        | "a 2.3"  | ["a", " ", "2", ".", "3"]  |
        | "a 2.4"  | ["a", " ", "2", ".", "4"]  |
        | "b"      | ["b"]                      |
        | "b 1.1"  | ["b", " ", "1", ".", "1"]  |
        +----------+----------------------------+
END
    end

    it "nums" do
      expect(table(versions.map(&:nums)))
        .to eq(<<~END.strip)
        +----------+------------------------+
        | ""       | []                     |
        | "1"      | [1]                    |
        | "2"      | [2]                    |
        | "1.2"    | [1, nil, 2]            |
        | "1.2.1"  | [1, nil, 2, nil, 1]    |
        | "1.23a"  | [1, nil, 23, nil]      |
        | "1.23-b" | [1, nil, 23, nil, nil] |
        | "a 2.3"  | [nil, nil, 2, nil, 3]  |
        | "a 2.4"  | [nil, nil, 2, nil, 4]  |
        | "b"      | [nil]                  |
        | "b 1.1"  | [nil, nil, 1, nil, 1]  |
        +----------+------------------------+
END
    end

    it "to_a" do
      expect(table(versions.map(&:to_a)))
      .to eq(<<~END.strip)
      +----------+------------------------+
      | ""       | []                     |
      | "1"      | [1]                    |
      | "2"      | [2]                    |
      | "1.2"    | [1, ".", 2]            |
      | "1.2.1"  | [1, ".", 2, ".", 1]    |
      | "1.23a"  | [1, ".", 23, "a"]      |
      | "1.23-b" | [1, ".", 23, "-", "b"] |
      | "a 2.3"  | ["a", " ", 2, ".", 3]  |
      | "a 2.4"  | ["a", " ", 2, ".", 4]  |
      | "b"      | ["b"]                  |
      | "b 1.1"  | ["b", " ", 1, ".", 1]  |
      +----------+------------------------+
END
    end

    it "sorts" do 
      shuffled = versions
      shuffled = versions.shuffle while shuffled == versions
      shuffled.sort!
      expect(shuffled.map(&:to_s))
        .to eq(["", "1", "1.2", "1.2.1", "1.23-b", "1.23a", "2", "a 2.3", "a 2.4", "b", "b 1.1"])
    end
  end
end
