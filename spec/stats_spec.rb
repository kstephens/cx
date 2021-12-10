require "cx/stats"
require "bigdecimal"
require "rational"

module CX
  RSpec.describe Stats do
    subject do
      Stats.new_from_hash(
        { n_bins: n_bins,
          values: values }.merge(opts)
      )
    end
    let(:actual) { subject.complete! }
    let(:domain) { 2..23 }
    let(:values_n) { 100 }
    let(:n_bins) { 13 }
    let(:random) { ::Random.new(1234346) }
    let(:opts) { {} }

    def rand_(domain); random.rand(domain); end

    describe "ratio_fn" do
      let(:values) { [2, 3, 5, 7] }
      let(:n_bins) { 4 }
      let(:opts) { { ratio_fn: Proc.new { |a, b| a.to_f / b.to_f } } }
      it "uses the ratio_fn" do
        expected =
          { :nils => 0,
            :count => 4,
            :sum => 17,
            :min => 2,
            :max => 7,
            :range => 2..7,
            :width => 5,
            :mean => 4.25,
            :stddev => 1.920286436967152,
            :mid => 1,
            :median => 4.0,
            :n_bins => 4,
            :bins_range => 2..7,
            :bins => [[2...3.25,
                       { 2 => 1, 3 => 1 }],
                      [3.25...4.5,
                       {}],
                      [4.5...5.75,
                       { 5 => 1 }],
                      [5.75..7,
                       { 7 => 1 }]],
            :value_types => [Integer],
            :value_type => Integer }
        verify! actual, expected
      end
    end

    describe "empty values" do
      let(:values) { [] }
      it "works" do
        expected = {
          :values => [],
          :nils => 0,
          :min => nil,
          :max => nil,
          :range => nil,
          :width => nil,
          :count => 0,
          :sum => nil,
          :mean => nil,
          :stddev => nil,
          :mid => nil,
          :median => nil,
          :n_bins => 13,
          :bins => nil,
          :bins_range => nil,
          :value_types => [],
          :value_type => nil,
        }
        verify! actual, expected
      end
    end

    describe "one value" do
      let(:values) { [3] }
      it "works" do
        expected =
          { :nils => 0,
            :count => 1,
            :sum => 3,
            :min => 3,
            :max => 3,
            :range => 3..3,
            :width => 0,
            :mean => 3,
            :stddev => nil,
            :mid => 0,
            :median => 3,
            :n_bins => 13,
            :bins_range => 3..3,
            :bins => [[3...4,
                       {}],
                      [4...5,
                       {}],
                      [5...6,
                       {}],
                      [6...7,
                       {}],
                      [7...8,
                       {}],
                      [8...9,
                       {}],
                      [9...10,
                       {}],
                      [10...11,
                       {}],
                      [11...12,
                       {}],
                      [12...13,
                       {}],
                      [13...14,
                       {}],
                      [14...15,
                       {}],
                      [15...16,
                       { 3 => 1 }]],
            :value_types => [Integer],
            :value_type => Integer }
        verify! actual, expected
      end
    end

    describe "two integers" do
      let(:values) { [3, 4] }
      it "works" do
        expected =
          { :nils => 0,
            :count => 2,
            :sum => 7,
            :min => 3,
            :max => 4,
            :range => 3..4,
            :width => 1,
            :mean => Rational(7, 2),
            :stddev => 0.5,
            :mid => 0,
            :median => Rational(7, 2),
            :n_bins => 13,
            :bins_range => 3..4,
            :bins => [[3...Rational(40, 13),
                       { 3 => 1 }],
                      [Rational(40, 13)...Rational(41, 13),
                       {}],
                      [Rational(41, 13)...Rational(42, 13),
                       {}],
                      [Rational(42, 13)...Rational(43, 13),
                       {}],
                      [Rational(43, 13)...Rational(44, 13),
                       {}],
                      [Rational(44, 13)...Rational(45, 13),
                       {}],
                      [Rational(45, 13)...Rational(46, 13),
                       {}],
                      [Rational(46, 13)...Rational(47, 13),
                       {}],
                      [Rational(47, 13)...Rational(48, 13),
                       {}],
                      [Rational(48, 13)...Rational(49, 13),
                       {}],
                      [Rational(49, 13)...Rational(50, 13),
                       {}],
                      [Rational(50, 13)...Rational(51, 13),
                       {}],
                      [Rational(51, 13)..4,
                       { 4 => 1 }]],
            :value_types => [Integer],
            :value_type => Integer }
        verify! actual, expected
      end
    end

    describe "3 integers" do
      let(:values) { [2, 3, 5] }
      it "works" do
        expected = { :nils => 0,
                     :count => 3,
                     :sum => 10,
                     :min => 2,
                     :max => 5,
                     :range => 2..5,
                     :width => 3,
                     :mean => Rational(10, 3),
                     :stddev => 1.247219128924647,
                     :mid => 1,
                     :median => 3,
                     :n_bins => 13,
                     :bins_range => 2..5,
                     :bins => [[2...Rational(29, 13),
                                { 2 => 1 }],
                               [Rational(29, 13)...Rational(32, 13),
                                {}],
                               [Rational(32, 13)...Rational(35, 13),
                                {}],
                               [Rational(35, 13)...Rational(38, 13),
                                {}],
                               [Rational(38, 13)...Rational(41, 13),
                                { 3 => 1 }],
                               [Rational(41, 13)...Rational(44, 13),
                                {}],
                               [Rational(44, 13)...Rational(47, 13),
                                {}],
                               [Rational(47, 13)...Rational(50, 13),
                                {}],
                               [Rational(50, 13)...Rational(53, 13),
                                {}],
                               [Rational(53, 13)...Rational(56, 13),
                                {}],
                               [Rational(56, 13)...Rational(59, 13),
                                {}],
                               [Rational(59, 13)...Rational(62, 13),
                                {}],
                               [Rational(62, 13)..5,
                                { 5 => 1 }]],
                     :value_types => [Integer],
                     :value_type => Integer }
        verify! actual, expected
      end
    end

    describe "4 integers" do
      let(:values) { [7, 11, 13, 17] }
      it "works" do
        expected =
          { :nils => 0,
            :count => 4,
            :sum => 48,
            :min => 7,
            :max => 17,
            :range => 7..17,
            :width => 10,
            :mean => Rational(12, 1),
            :stddev => 3.605551275463989,
            :mid => 1,
            :median => Rational(12, 1),
            :n_bins => 13,
            :bins_range => 7..17,
            :bins => [[7...Rational(101, 13),
                       { 7 => 1 }],
                      [Rational(101, 13)...Rational(111, 13),
                       {}],
                      [Rational(111, 13)...Rational(121, 13),
                       {}],
                      [Rational(121, 13)...Rational(131, 13),
                       {}],
                      [Rational(131, 13)...Rational(141, 13),
                       {}],
                      [Rational(141, 13)...Rational(151, 13),
                       { 11 => 1 }],
                      [Rational(151, 13)...Rational(161, 13),
                       {}],
                      [Rational(161, 13)...Rational(171, 13),
                       { 13 => 1 }],
                      [Rational(171, 13)...Rational(181, 13),
                       {}],
                      [Rational(181, 13)...Rational(191, 13),
                       {}],
                      [Rational(191, 13)...Rational(201, 13),
                       {}],
                      [Rational(201, 13)...Rational(211, 13),
                       {}],
                      [Rational(211, 13)..17,
                       { 17 => 1 }]],
            :value_types => [Integer],
            :value_type => Integer }
        verify! actual, expected
      end
    end

    describe "flat distribution" do
      let(:values) do
        width = domain.max - domain.min
        (0...values_n).map do |i|
          domain.min + (i % width)
        end
      end

      describe "integers" do
        it "works" do
          expected =
            { :nils => 0,
              :count => 100,
              :sum => 1160,
              :min => 2,
              :max => 22,
              :range => 2..22,
              :width => 20,
              :mean => Rational(58, 5),
              :stddev => 5.919459434779497,
              :mid => 49,
              :median => Rational(23, 2),
              :n_bins => 13,
              :bins_range => 2..22,
              :bins => [
              [2...Rational(46, 13),
               { 2 => 5, 3 => 5 }],
              [Rational(46, 13)...Rational(66, 13),
               { 4 => 5, 5 => 5 }],
              [Rational(66, 13)...Rational(86, 13),
               { 6 => 5 }],
              [Rational(86, 13)...Rational(106, 13),
               { 7 => 5, 8 => 5 }],
              [Rational(106, 13)...Rational(126, 13),
               { 9 => 5 }],
              [Rational(126, 13)...Rational(146, 13),
               { 10 => 5, 11 => 5 }],
              [Rational(146, 13)...Rational(166, 13),
               { 12 => 5 }],
              [Rational(166, 13)...Rational(186, 13),
               { 13 => 5, 14 => 5 }],
              [Rational(186, 13)...Rational(206, 13),
               { 15 => 5 }],
              [Rational(206, 13)...Rational(226, 13),
               { 16 => 5, 17 => 5 }],
              [Rational(226, 13)...Rational(246, 13),
               { 18 => 4 }],
              [Rational(246, 13)...Rational(266, 13),
               { 19 => 4, 20 => 4 }],
              [Rational(266, 13)..22,
               { 21 => 4, 22 => 4 }],
            ],
              :value_types => [Integer],
              :value_type => Integer }
          a = actual    # touch_up!(actual)
          e = expected  # touch_up!(expected)
          verify! a, e
        end
      end

      describe "non-integers" do
        let(:domain) { 2.0..23.0 }
        it "works" do
          expected =
            { :nils => 0,
              :count => 100,
              :sum => 1160.0,
              :min => 2.0,
              :max => 22.0,
              :range => 2.0..22.0,
              :width => 20.0,
              :mean => 11.6,
              :stddev => 5.919459434779497,
              :mid => 49,
              :median => 11.5,
              :n_bins => 13,
              :bins_range => 2.0..22.0,
              :bins => [
              [2.0...3.5384615384615383,
               { 2.0 => 5, 3.0 => 5 }],
              [3.5384615384615383...5.076923076923077,
               { 4.0 => 5, 5.0 => 5 }],
              [5.076923076923077...6.615384615384615,
               { 6.0 => 5 }],
              [6.615384615384615...8.153846153846153,
               { 7.0 => 5, 8.0 => 5 }],
              [8.153846153846153...9.692307692307692,
               { 9.0 => 5 }],
              [9.692307692307692...11.23076923076923,
               { 10.0 => 5, 11.0 => 5 }],
              [11.23076923076923...12.769230769230768,
               { 12.0 => 5 }],
              [12.769230769230768...14.307692307692307,
               { 13.0 => 5, 14.0 => 5 }],
              [14.307692307692307...15.846153846153845,
               { 15.0 => 5 }],
              [15.846153846153845...17.384615384615383,
               { 16.0 => 5, 17.0 => 5 }],
              [17.384615384615383...18.923076923076923,
               { 18.0 => 4 }],
              [18.923076923076923...20.46153846153846,
               { 19.0 => 4, 20.0 => 4 }],
              [20.46153846153846..22.0,
               { 21.0 => 4, 22.0 => 4 }],
            ],
              :value_types => [Float],
              :value_type => Float }
          a = clean_up!(actual)
          e = clean_up!(expected)
          verify! a, e
        end
      end

      def touch_up_bins!(h)
        h = h.to_h
        (h[:bins] || []).each! { |b| b[0] = b[0].min }
        h
      end
    end

    describe "random distribution" do
      let(:values) do
        (0...values_n).flat_map do |i|
          v = nil_freq && rand_(nil_freq).zero? ? nil : rand_(domain)
          n = dup_freq && rand_(dup_freq).zero? ? 1 : rand_(dup_size)
          [v] * n
        end
      end
      let(:nil_freq) { 11 }
      let(:dup_freq) { 7 }
      let(:dup_size) { 5 }

      describe "integers" do
        let(:domain) { 10..97 }
        it "works" do
          expected = {
            :nils => 17,
            :count => 180,
            :sum => 9384,
            :min => 12,
            :max => 97,
            :range => 12..97,
            :width => 85,
            :mean => Rational(782, 15),
            :stddev => 25.74088835555862,
            :mid => 89,
            :median => Rational(47, 1),
            :n_bins => 13,
            :bins_range => 12..97,
            :bins => [
              [12...Rational(241, 13),
               { 12 => 1,
                 13 => 1,
                 14 => 1,
                 16 => 8,
                 17 => 2 }],
              [Rational(241, 13)...Rational(326, 13),
               { 19 => 3, 20 => 4, 22 => 6, 23 => 5, 25 => 8 }],
              [Rational(326, 13)...Rational(411, 13),
               { 26 => 4, 27 => 2, 29 => 5, 30 => 2 }],
              [Rational(411, 13)...Rational(496, 13),
               { 32 => 4, 33 => 3, 34 => 3, 36 => 4 }],
              [Rational(496, 13)...Rational(581, 13),
               { 40 => 2, 41 => 8, 42 => 4, 43 => 5, 44 => 2 }],
              [Rational(581, 13)...Rational(666, 13),
               { 46 => 1, 47 => 4, 49 => 2, 50 => 5 }],
              [Rational(666, 13)...Rational(751, 13),
               { 57 => 2 }],
              [Rational(751, 13)...Rational(836, 13),
               { 60 => 1, 61 => 1, 62 => 4, 63 => 4, 64 => 1 }],
              [Rational(836, 13)...Rational(921, 13),
               { 65 => 1, 66 => 5, 67 => 4, 68 => 2, 70 => 1 }],
              [Rational(921, 13)...Rational(1006, 13),
               { 71 => 3, 72 => 1, 73 => 1, 74 => 6, 76 => 2 }],
              [Rational(1006, 13)...Rational(1091, 13),
               { 78 => 1, 80 => 4, 81 => 3, 83 => 3 }],
              [Rational(1091, 13)...Rational(1176, 13),
               { 84 => 3, 86 => 2, 87 => 2, 88 => 9, 90 => 1 }],
              [Rational(1176, 13)..97,
               { 91 => 2, 93 => 7, 95 => 4, 97 => 1 }],
            ],
            :value_types => [Integer],
            :value_type => Integer,
          }
          verify! actual, expected
        end
      end

      describe "non-integers" do
        let(:domain) { 10.0..97.0 }
        it "works" do
          expected =
            { :nils => 19,
              :count => 182,
              :sum => 10842.82844527419,
              :min => 10.271889398044452,
              :max => 96.69951376738433,
              :range => 10.271889398044452..96.69951376738433,
              :width => 86.42762436933988,
              :mean => 59.575980468539505,
              :stddev => 26.22725839425758,
              :mid => 90,
              :median => 66.50022345833153,
              :n_bins => 13,
              :bins_range => 10.271889398044452..96.69951376738433,
              :bins => [[10.271889398044452...16.92016819568598,
                         { 10.271889398044452 => 2,
                          10.50726376369491 => 3,
                          10.629780833039739 => 4,
                          12.429605560249481 => 1,
                          12.498893070385991 => 4,
                          15.343863630056967 => 1,
                          16.132598743883836 => 4,
                          16.86007584542094 => 1 }],
                        [16.92016819568598...23.568446993327512,
                         { 16.931295781369904 => 4,
                          20.144134775378916 => 2 }],
                        [23.568446993327512...30.216725790969043,
                         { 24.0778018563041 => 1,
                          26.790570815426506 => 1, 27.678301829841164 => 1 }],
                        [30.216725790969043...36.86500458861057,
                         { 32.01397662012694 => 1,
                          32.278551574932465 => 4,
                          32.32291768498009 => 1,
                          33.42816586150878 => 1,
                          34.28495529408162 => 3,
                          34.33217609600298 => 1 }],
                        [36.86500458861057...43.5132833862521,
                         { 39.52442782845175 => 4,
                          40.334078332020695 => 4,
                          41.87828175274684 => 2,
                          42.8697245860281 => 4 }],
                        [43.5132833862521...50.16156218389363,
                         { 44.094022640487 => 3,
                          44.58026361520247 => 3,
                          46.98525505310348 => 1,
                          47.85765612261285 => 2,
                          48.601764231249724 => 4 }],
                        [50.16156218389363...56.80984098153515,
                         { 50.688670648984264 => 2,
                          53.08180530810877 => 1,
                          55.171210963795794 => 1 }],
                        [56.80984098153515...63.458119779176684,
                         { 58.94584014194847 => 1,
                          59.068428994235404 => 1,
                          59.51803300869319 => 4,
                          59.80619981301329 => 2,
                          61.16438371429842 => 1,
                          61.326719755762845 => 4,
                          61.846389209569196 => 4 }],
                        [63.458119779176684...70.10639857681822,
                         { 66.17147658676203 => 1,
                          66.50022345833153 => 3,
                          68.1673313943451 => 4,
                          68.3081741249906 => 4,
                          68.50388620213516 => 2,
                          69.51398460002719 => 1 }],
                        [70.10639857681822...76.75467737445975,
                         { 70.21471640848537 => 3,
                          70.25663545619629 => 2,
                          71.27337631579896 => 3,
                          73.59212258429032 => 2,
                          74.41910962943714 => 4 }],
                        [76.75467737445975...83.40295617210127,
                         { 77.26937701935742 => 2,
                          78.12965814519636 => 3,
                          78.38776871428823 => 4,
                          78.51031283759156 => 3,
                          78.51219093536568 => 4,
                          78.53945755010385 => 3,
                          78.72894394302838 => 2,
                          79.45553045141556 => 4,
                          80.06579667921656 => 2,
                          81.9702499408712 => 3 }],
                        [83.40295617210127...90.05123496974281,
                         { 85.0300147283902 => 4,
                          86.64866376160249 => 1,
                          86.68427467485397 => 2,
                          87.37435431466628 => 1,
                          87.52050493390938 => 1 }],
                        [90.05123496974281..96.69951376738433,
                         { 90.22664156922023 => 3,
                          91.2498177826087 => 1,
                          92.80817209010566 => 2,
                          93.4603358288885 => 1,
                          94.44852173825237 => 4,
                          94.6342367070968 => 4,
                          94.78455305089958 => 3,
                          95.25429120377001 => 4,
                          96.69951376738433 => 4 }]],
              :value_types => [Float],
              :value_type => Float }
          verify! actual, expected
        end
      end
    end

    ##########################################

    def verify!(actual, expected)
      actual = clean_up!(actual)
      expected = clean_up!(expected)
      diff = hash_diff(actual, expected)
      unless diff.empty?
        pp(expected: expected)
        pp(actual: actual)
      end
      expect(
        expected: expected,
        actual: actual,
        diff: diff,
      ).to eq(
        expected: expected,
        actual: actual,
        diff: {},
      )
    end

    def hash_diff(a, b)
      diff = {}
      missing = :'*MISSING*'
      Set.new(a.keys + b.keys).sort.each do |k|
        v1 = a.key?(k) ? a[k] : missing
        v2 = b.key?(k) ? b[k] : missing
        unless v1 == v2 && v1.class == v2.class
          diff[k] = [v1, v2]
        end
      end
      diff
    end

    def clean_up!(h)
      h = h.to_h.dup
      h.delete(:id)
      h.delete(:val_to_idx)
      h.delete(:idx_to_val)
      h.delete(:ratio_fn)
      if h[:values]
        expect(h[:values]).to eq(values.sort)
      end
      h.delete(:values)

      if bins = h[:bins]
        expect(bins.size).to eq(h[:n_bins])
        if false
          expect(bins[0].first.min).to eq(h[:min])
          expect(bins[-1].first.max).to eq(h[:max])
        end
      end
      h
    end
  end
end
