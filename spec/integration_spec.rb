# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
CX::Xform.require_all!

module CX
  module Xform
    RSpec.describe 'Xform' do
      include CX::Test
      it "Grep" do
        assert_pipeline(Grep.new(["a:-8"]), <<"END")
id,a,b,b4,X %
1023,-82,pmc,8.8,63%
1064,-81,dwn ,25.2,103%
1077,-80,fin,30.4,161%
1097,-88,jte ,38.4,170%
END
        
        assert_pipeline(Grep.new(["id:!;^10[1-9]"]), <<"END")
id,a,b,b4,X %
1001,79,ekl ,"",133%
1002,77,ymt,0.4,48%
1003,84,yis,0.8,12%
1004,-62,rcz ,1.2,127%
1005,-38,oub,1.6,9%
1006,67,hjn,"",187%
1007,-72,xgv ,2.4,55%
1008,-21,qeg,2.8,135%
1009,-99,ali,3.2,191%
1100,-27,ylb ,39.6,39%
END
      end
    end
  end
end
