# coding: utf-8
# frozen_string_literal: true

require 'cx'
require 'cx/xform'
CX::Xform.require_all!

module CX
  module Xform
    RSpec.describe 'Xform' do
      include CX::Test

      it "Grep" do
        assert_pipeline build(Grep, "a:-8"), <<'END', size: 100
|id,a,b,b4,X %|
|1023,-82,pmc,8.8,63%|
|1064,-81,dwn ,25.2,103%|
|1077,-80,fin,30.4,161%|
|1097,-88,jte ,38.4,170%|
END

      end
      
      it "Grep : negated" do
        assert_pipeline build(Grep, "id:!;^10[1-9]"), <<'END', size: 100
|id,a,b,b4,X %|
|1001,79,ekl ,"",133%|
|1002,77,ymt,0.4,48%|
|1003,84,yis,0.8,12%|
|1004,-62,rcz ,1.2,127%|
|1005,-38,oub,1.6,9%|
|1006,67,hjn,"",187%|
|1007,-72,xgv ,2.4,55%|
|1008,-21,qeg,2.8,135%|
|1009,-99,ali,3.2,191%|
|1100,-27,ylb ,39.6,39%|
END
      end

      it "Sort" do
        assert_pipeline build(Sort, "b"), <<'END', size: 5
|id,a,b,b4,X %|
|1001,79,ekl ,"",133%|
|1005,-38,oub,1.6,9%|
|1004,-62,rcz ,1.2,127%|
|1003,84,yis,0.8,12%|
|1002,77,ymt,0.4,48%|
END
      end

      it "Sort : reverse" do
        assert_pipeline (Pipeline | MetaIn | build(Sort, "b:-")), <<'END', size: 5
|id,a,b,b4,X %|
|1002,77,ymt,0.4,48%|
|1003,84,yis,0.8,12%|
|1004,-62,rcz ,1.2,127%|
|1005,-38,oub,1.6,9%|
|1001,79,ekl ,"",133%|
END
      end

      # FIXME!!!
      it "Sort : numerically" do
        assert_pipeline (Pipeline | build(Replace, "x_:%;") | MetaIn | Coerce | build(Sort, "x_:-")), <<'END', size: 5
|id,a,b,b4,X %|
|1005,-38,oub,1.6,9|
|1002,77,ymt,0.4,48|
|1001,79,ekl ,"",133|
|1004,-62,rcz ,1.2,127|
|1003,84,yis,0.8,12|
END
      end

      it "Replace" do
        assert_pipeline build(Replace, "x_:%;"), <<'END', size: 5
|id,a,b,b4,X %|
|1001,79,ekl ,"",133|
|1002,77,ymt,0.4,48|
|1003,84,yis,0.8,12|
|1004,-62,rcz ,1.2,127|
|1005,-38,oub,1.6,9|
END
      end

      it "Replace : all" do
        assert_pipeline build(Replace, "--search=1", "--replace=_"), <<'END', size: 5
|id,a,b,b4,X %|
|_001,79,ekl ,"",_33%|
|_002,77,ymt,0.4,48%|
|_003,84,yis,0.8,_2%|
|_004,-62,rcz ,_.2,_27%|
|_005,-38,oub,_.6,9%|
END
      end

      it "Replace : all : --global" do
        assert_pipeline build(Replace, "--search=1", "--replace=_", "--global"), <<'END', size: 5
|id,a,b,b4,X %|
|_00_,79,ekl ,"",_33%|
|_002,77,ymt,0.4,48%|
|_003,84,yis,0.8,_2%|
|_004,-62,rcz ,_.2,_27%|
|_005,-38,oub,_.6,9%|
END
      end

      it "Replace | MetaIn" do
        assert_pipeline (Pipeline | build(Replace, "x_:%;") | MetaIn | MetaTable), <<'END', size: 5
|name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred|
|id,id,true,0,0,Integer,4,4,1001,1005,0,0,,,right,Integer,Integer|
|a,a,true,1,1,,2,3,-62,84,0,0,,,right,Integer,Integer|
|b,b,true,2,2,,3,4,ekl ,ymt,0,0,,,,String,String|
|b4,b4,true,3,3,,0,6,"","",1,0,,,,String;BigDecimal,Object|
|X %,x_,true,4,4,String,1,4,9,133,0,0,,,right,Integer,Integer|
END
      end

      it "Replace | MetaIn | Coerce" do
        assert_pipeline (Pipeline | build(Replace, "x_:%;") | MetaIn | Coerce), <<'END', size: 5
|id,a,b,b4,X %|
|1001,79,ekl ,"",133|
|1002,77,ymt,0.4,48|
|1003,84,yis,0.8,12|
|1004,-62,rcz ,1.2,127|
|1005,-38,oub,1.6,9|
END
      end

      it "Replace | MetaIn | Coerce | MetaTable" do
        assert_pipeline (Pipeline | build(Replace, "x_:%;") | MetaIn | Coerce | build(MetaIn, "--clear-type") | MetaTable), <<'END', size: 5
|name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred|
|id,id,true,0,0,,4,4,1001,1005,0,0,,,right,Integer,Integer|
|a,a,true,1,1,,2,3,-62,84,0,0,,,right,Integer,Integer|
|b,b,true,2,2,,3,4,ekl ,ymt,0,0,,,,String,String|
|b4,b4,true,3,3,,0,6,"","",1,0,,,,String;BigDecimal,Object|
|X %,x_,true,4,4,,1,4,9,133,0,0,,,right,Integer,Integer|
END
      end

      it "Region" do
        assert_pipeline build(Region, "11..23"), <<'END', size: 100
|id,a,b,b4,X %|
|1011,39,axr,"",97%|
|1012,-38,wky,4.4,60%|
|1013,73,dmm ,4.8,197%|
|1014,48,gys,5.2,49%|
|1015,-92,ndu,5.6,80%|
|1016,-44,ndr ,"",26%|
|1017,-71,ewo,6.4,173%|
|1018,26,cwc,6.8,186%|
|1019,-72,cag ,7.2,50%|
|1020,51,iws,7.6,145%|
|1021,18,ypl,"",143%|
|1022,29,jer ,8.4,184%|
|1023,-82,pmc,8.8,63%|
END
      end

      it "Region : reverse" do
        assert_pipeline build(Region, "9..1"), <<'END', size: 100
|id,a,b,b4,X %|
|1009,-99,ali,3.2,191%|
|1008,-21,qeg,2.8,135%|
|1007,-72,xgv ,2.4,55%|
|1006,67,hjn,"",187%|
|1005,-38,oub,1.6,9%|
|1004,-62,rcz ,1.2,127%|
|1003,84,yis,0.8,12%|
|1002,77,ymt,0.4,48%|
|1001,79,ekl ,"",133%|
END
      end

      it "Region : reverse" do
        assert_pipeline build(Region, "9..1"), <<'END', size: 100
|id,a,b,b4,X %|
|1009,-99,ali,3.2,191%|
|1008,-21,qeg,2.8,135%|
|1007,-72,xgv ,2.4,55%|
|1006,67,hjn,"",187%|
|1005,-38,oub,1.6,9%|
|1004,-62,rcz ,1.2,127%|
|1003,84,yis,0.8,12%|
|1002,77,ymt,0.4,48%|
|1001,79,ekl ,"",133%|
END
      end

      it "Region : negative offset" do
        $stop = true
        assert_pipeline build(Region, '-5..-1'), <<'END', size: 100
|id,a,b,b4,X %|
|1096,-9,ywj,"",127%|
|1097,-88,jte ,38.4,170%|
|1098,56,gns,38.8,64%|
|1099,-4,sod,39.2,151%|
|1100,-27,ylb ,39.6,39%|
END
      end
      
      it "Region : negative offset" do
        assert_pipeline build(Region, '-1..-5'), <<'END', size: 100
|id,a,b,b4,X %|
|1100,-27,ylb ,39.6,39%|
|1099,-4,sod,39.2,151%|
|1098,56,gns,38.8,64%|
|1097,-88,jte ,38.4,170%|
|1096,-9,ywj,"",127%|
END
      end

      it "Region : nothing" do
        assert_pipeline build(Region), <<'END', size: 100
|id,a,b,b4,X %|
END
      end

      it "Cut" do
        assert_pipeline build(Cut, 'b', 'a'), <<'END', size: 5
|b,a|
|ekl ,79|
|ymt,77|
|yis,84|
|rcz ,-62|
|oub,-38|
END
      end

      it "Cut : reorder/remove fields" do
        assert_pipeline build(Cut, 'b', '*', 'id:-'), <<'END', size: 5
|b,a,b4,X %|
|ekl ,79,"",133%|
|ymt,77,0.4,48%|
|yis,84,0.8,12%|
|rcz ,-62,1.2,127%|
|oub,-38,1.6,9%|
END
      end

      it "Cut : negative wildcard" do
        assert_pipeline build(Cut, 'b', '*-', 'id'), <<'END', size: 5
|b,id|
|ekl ,1001|
|ymt,1002|
|yis,1003|
|rcz ,1004|
|oub,1005|
END
      end

      it "Cut : duplicate fields" do
        assert_pipeline build(Cut, 'b', 'a', 'b'), <<'END', size: 5
|b,a,b3|
|ekl ,79,ekl |
|ymt,77,ymt|
|yis,84,yis|
|rcz ,-62,rcz |
|oub,-38,oub|
END
      end

      it "Transpose" do
        assert_pipeline Pipeline | MetaTable | Transpose, <<'END', size: 5
|_COL_1,_COL_2,_COL_3,_COL_4,_COL_5,_COL_6|
|name,id,a,b,b4,X %|
|name_,id,a,b,b4,x_|
|visible,true,true,true,true,true|
|order,0,1,2,3,4|
|index,0,1,2,3,4|
|type,Integer,,,,Numeric|
|min_size,4,2,3,0,2|
|max_size,4,3,4,6,4|
|min_value,1001,-62,ekl ,"",12%|
|max_value,1005,84,ymt,"",9%|
|blanks,0,0,0,1,0|
|nulls,0,0,0,0,0|
|format,,,,,|
|align,,,,,|
|align_inferred,right,right,,,|
|types,Integer,Integer,String,String;BigDecimal,String|
|type_inferred,Integer,Integer,String,Object,String|
END
      end
      
      it "Transpose : --no-include-header" do
        assert_pipeline Pipeline | MetaTable | build(Transpose, "--no-include-header"), <<'END', size: 5
|_COL_1,_COL_2,_COL_3,_COL_4,_COL_5|
|id,a,b,b4,X %|
|id,a,b,b4,x_|
|true,true,true,true,true|
|0,1,2,3,4|
|0,1,2,3,4|
|Integer,,,,Numeric|
|4,2,3,0,2|
|4,3,4,6,4|
|1001,-62,ekl ,"",12%|
|1005,84,ymt,"",9%|
|0,0,0,1,0|
|0,0,0,0,0|
|,,,,|
|,,,,|
|right,right,,,|
|Integer,Integer,String,String;BigDecimal,String|
|Integer,Integer,String,Object,String|
END
      end

      it "MetaTable" do
        assert_pipeline MetaTable, <<'END', size: 100
|name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred|
|id,id,true,0,0,Integer,4,4,1001,1100,0,0,,,right,Integer,Integer|
|a,a,true,1,1,,1,4,-100,95,0,0,,,right,Integer,Integer|
|b,b,true,2,2,,3,4,ali,zwq,0,0,,,,String,String|
|b4,b4,true,3,3,,0,7,"","",20,0,,,,String;BigDecimal,Object|
|X %,x_,true,4,4,Numeric,2,4,1%,98%,0,0,,,,String,String|
END
      end
      
      it "MetaTable | MetaTable" do
        assert_pipeline Pipeline | MetaTable | MetaTable, <<'END', size: 100
|name,name_,visible,order,index,type,min_size,max_size,min_value,max_value,blanks,nulls,format,align,align_inferred,types,type_inferred|
|name,name,true,0,0,Symbol,1,3,X %,id,0,0,,,,Symbol,Symbol|
|name_,name_,true,1,1,Symbol,1,2,a,x_,0,0,,,,Symbol,Symbol|
|visible,visible,true,2,2,Boolean,4,4,true,true,0,0,,,,TrueClass,TrueClass|
|order,order,true,3,3,Integer,1,1,0,4,0,0,,right,right,Integer,Integer|
|index,index,true,4,4,Integer,1,1,0,4,0,0,,right,right,Integer,Integer|
|type,type,true,5,5,Module,7,7,Integer,Numeric,0,3,,,,Class;NilClass,Class|
|min_size,min_size,true,6,6,Integer,1,1,0,4,0,0,,right,right,Integer,Integer|
|max_size,max_size,true,7,7,Integer,1,1,4,7,0,0,,right,right,Integer,Integer|
|min_value,min_value,true,8,8,,0,4,-100,1001,1,0,,,,Integer;String,Object|
|max_value,max_value,true,9,9,,0,4,95,1100,1,0,,,,Integer;String,Object|
|blanks,blanks,true,10,10,Integer,1,2,0,20,0,0,,right,right,Integer,Integer|
|nulls,nulls,true,11,11,Integer,1,1,0,0,0,0,,right,right,Integer,Integer|
|format,format,true,12,12,String,,,,,0,5,,,,NilClass,|
|align,align,true,13,13,Symbol,,,,,0,5,,,,NilClass,|
|align_inferred,align_inferred,true,14,14,Symbol,5,5,right,right,0,3,,,,Symbol;NilClass,Symbol|
|types,types,true,15,15,Set,16,28,Integer,Integer,0,0,,,,Set,Set|
|type_inferred,type_inferred,true,16,16,Module,6,7,Integer,Object,0,0,,,,Class,Class|
END
      end
      
      it "MarkdownOut" do
        assert_pipeline nil, <<'END', output_format: MarkdownOut
|| id    | a     | b     | b4     | X %   ||
|| ----: | ----: | ----- | ------ | ----: ||
||  1001 |    79 | ekl   |        |  133% ||
||  1002 |    77 | ymt   | 0.4    |   48% ||
||  1003 |    84 | yis   | 0.8    |   12% ||
||  1004 |   -62 | rcz   | 1.2    |  127% ||
||  1005 |   -38 | oub   | 1.6    |    9% ||
||  1006 |    67 | hjn   |        |  187% ||
||  1007 |   -72 | xgv   | 2.4    |   55% ||
||  1008 |   -21 | qeg   | 2.8    |  135% ||
||  1009 |   -99 | ali   | 3.2    |  191% ||
||  1010 |   -71 | jtj   | 3.6    |   25% ||
END
      end

      it "MarkdownOut : --no-include-header" do
        assert_pipeline nil, <<'END', output_format: build(MarkdownOut, '--no-include-header')
||  1001 |    79 | ekl   |        |  133% ||
||  1002 |    77 | ymt   | 0.4    |   48% ||
||  1003 |    84 | yis   | 0.8    |   12% ||
||  1004 |   -62 | rcz   | 1.2    |  127% ||
||  1005 |   -38 | oub   | 1.6    |    9% ||
||  1006 |    67 | hjn   |        |  187% ||
||  1007 |   -72 | xgv   | 2.4    |   55% ||
||  1008 |   -21 | qeg   | 2.8    |  135% ||
||  1009 |   -99 | ali   | 3.2    |  191% ||
||  1010 |   -71 | jtj   | 3.6    |   25% ||
END
      end

      it "HTMLOut: Full" do
        format = build(HTMLOut, '--filtering')
        result = run_pipeline(Pipeline | MetaIn | Quote, output_format: format, size: 1000)
        File.write("tmp/test.html", result)
        # puts result
      end
      
      it "HTMLOut" do
        format = build(HTMLOut, "--table-only", '--no-styled', '--no-filtering', '--no-sorting', '--indent=2')
        assert_pipeline nil, <<'END', output_format: format, size: 5
|<table>|
|  <thead>|
|    <tr>|
|      <th>#</th>|
|      <th>id</th>|
|      <th>a</th>|
|      <th>b</th>|
|      <th>b4</th>|
|      <th>X %</th>|
|    </tr>|
|  </thead>|
|  <tbody>|
|    <tr>|
|      <td>1</td>|
|<td>1001</td><td>79</td><td>ekl </td><td></td><td>133%</td>    </tr>|
|    <tr>|
|      <td>2</td>|
|<td>1002</td><td>77</td><td>ymt</td><td>0.4</td><td>48%</td>    </tr>|
|    <tr>|
|      <td>3</td>|
|<td>1003</td><td>84</td><td>yis</td><td>0.8</td><td>12%</td>    </tr>|
|    <tr>|
|      <td>4</td>|
|<td>1004</td><td>-62</td><td>rcz </td><td>1.2</td><td>127%</td>    </tr>|
|    <tr>|
|      <td>5</td>|
|<td>1005</td><td>-38</td><td>oub</td><td>1.6</td><td>9%</td>    </tr>|
|  </tbody>|
|</table>|
END
      end

      it "HTMLOut : --no-include-header" do
        format = build(HTMLOut, "--table-only", '--no-styled', '--no-filtering', '--no-sorting', '--indent=2', '--no-include-header')
        assert_pipeline nil, <<'END', output_format: format, size: 5
|<table>|
|  <tbody>|
|    <tr>|
|      <td>1</td>|
|<td>1001</td><td>79</td><td>ekl </td><td></td><td>133%</td>    </tr>|
|    <tr>|
|      <td>2</td>|
|<td>1002</td><td>77</td><td>ymt</td><td>0.4</td><td>48%</td>    </tr>|
|    <tr>|
|      <td>3</td>|
|<td>1003</td><td>84</td><td>yis</td><td>0.8</td><td>12%</td>    </tr>|
|    <tr>|
|      <td>4</td>|
|<td>1004</td><td>-62</td><td>rcz </td><td>1.2</td><td>127%</td>    </tr>|
|    <tr>|
|      <td>5</td>|
|<td>1005</td><td>-38</td><td>oub</td><td>1.6</td><td>9%</td>    </tr>|
|  </tbody>|
|</table>|
END
      end


      it "Eval" do
        assert_pipeline build(Eval, '_.foo = "#{a} #{b}"'), <<'END'
|id,a,b,b4,X %,foo|
|1001,79,ekl ,"",133%,79 ekl |
|1002,77,ymt,0.4,48%,77 ymt|
|1003,84,yis,0.8,12%,84 yis|
|1004,-62,rcz ,1.2,127%,-62 rcz |
|1005,-38,oub,1.6,9%,-38 oub|
|1006,67,hjn,"",187%,67 hjn|
|1007,-72,xgv ,2.4,55%,-72 xgv |
|1008,-21,qeg,2.8,135%,-21 qeg|
|1009,-99,ali,3.2,191%,-99 ali|
|1010,-71,jtj ,3.6,25%,-71 jtj |
END
      end

      it "RowId" do
        assert_pipeline build(RowId, '--start=13', '--name=the_id'), <<'END'
|the_id,id,a,b,b4,X %|
|13,1001,79,ekl ,"",133%|
|14,1002,77,ymt,0.4,48%|
|15,1003,84,yis,0.8,12%|
|16,1004,-62,rcz ,1.2,127%|
|17,1005,-38,oub,1.6,9%|
|18,1006,67,hjn,"",187%|
|19,1007,-72,xgv ,2.4,55%|
|20,1008,-21,qeg,2.8,135%|
|21,1009,-99,ali,3.2,191%|
|22,1010,-71,jtj ,3.6,25%|
END
      end

      it "Strip" do
        assert_pipeline build(Strip), <<'END'
|id,a,b,b4,X %|
|1001,79,ekl,"",133%|
|1002,77,ymt,0.4,48%|
|1003,84,yis,0.8,12%|
|1004,-62,rcz,1.2,127%|
|1005,-38,oub,1.6,9%|
|1006,67,hjn,"",187%|
|1007,-72,xgv,2.4,55%|
|1008,-21,qeg,2.8,135%|
|1009,-99,ali,3.2,191%|
|1010,-71,jtj,3.6,25%|
END
      end

      it "EmptyToNull" do
        assert_pipeline (Pipeline | Strip | EmptyToNull), <<'END'
|id,a,b,b4,X %|
|1001,79,ekl,,133%|
|1002,77,ymt,0.4,48%|
|1003,84,yis,0.8,12%|
|1004,-62,rcz,1.2,127%|
|1005,-38,oub,1.6,9%|
|1006,67,hjn,,187%|
|1007,-72,xgv,2.4,55%|
|1008,-21,qeg,2.8,135%|
|1009,-99,ali,3.2,191%|
|1010,-71,jtj,3.6,25%|
END
      end

      it "Quote" do
        assert_pipeline (Pipeline | Quote | EmptyToNull | MetaIn), <<'END', output_format: MarkdownOut
|| id    | a     | b      | b4     | X %   ||
|| ----: | ----: | ------ | -----: | ----: ||
||  1001 |    79 | "ekl " |        |  133% ||
||  1002 |    77 | ymt    |    0.4 |   48% ||
||  1003 |    84 | yis    |    0.8 |   12% ||
||  1004 |   -62 | "rcz " |    1.2 |  127% ||
||  1005 |   -38 | oub    |    1.6 |    9% ||
||  1006 |    67 | hjn    |        |  187% ||
||  1007 |   -72 | "xgv " |    2.4 |   55% ||
||  1008 |   -21 | qeg    |    2.8 |  135% ||
||  1009 |   -99 | ali    |    3.2 |  191% ||
||  1010 |   -71 | "jtj " |    3.6 |   25% ||
END
      end

      it "CsvIn" do
        input_data = <<'END'
a,b,c
1,2,3
x,y,z
END
        expected = <<'END'
|a,b,c|
|1,2,3|
|x,y,z|
END
        actual = assert_pipeline (Pipeline | HeaderIn), expected, input_data: input_data
      end
      
      it "HeaderOut : --meta-columns=name,..." do
        assert_pipeline (Pipeline | build(HeaderOut, '--meta-columns=name,min_size,blanks')), <<'END'
|__META__,id,a,b,b4,X %|
|__META__,id,a,b,b4,X %|
|name,id,a,b,b4,X %|
|min_size,4,2,3,0,2|
|blanks,0,0,0,2,0|
|"",1001,79,ekl ,"",133%|
|"",1002,77,ymt,0.4,48%|
|"",1003,84,yis,0.8,12%|
|"",1004,-62,rcz ,1.2,127%|
|"",1005,-38,oub,1.6,9%|
|"",1006,67,hjn,"",187%|
|"",1007,-72,xgv ,2.4,55%|
|"",1008,-21,qeg,2.8,135%|
|"",1009,-99,ali,3.2,191%|
|"",1010,-71,jtj ,3.6,25%|
END
      end

      it "SqlOut" do
        format = build SqlOut, "--table=the_table", '--create', '--transaction', '--commit', '--insert'
        assert_pipeline (Pipeline | MetaIn), <<'END', output_format: format
|START TRANSACTION;|
||
|CREATE TABLE the_table|
|(|
|  id INT,|
|  a INT,|
|  b VARCHAR(4),|
|  b4 TEXT,|
|  x_ TEXT|
|);|
||
|INSERT INTO the_table|
|  (id, a, b, b4, x_)|
|VALUES|
|  ('1001', '79', 'ekl ', '', '133%'),|
|  ('1002', '77', 'ymt', '0.4', '48%'),|
|  ('1003', '84', 'yis', '0.8', '12%'),|
|  ('1004', '-62', 'rcz ', '1.2', '127%'),|
|  ('1005', '-38', 'oub', '1.6', '9%'),|
|  ('1006', '67', 'hjn', '', '187%'),|
|  ('1007', '-72', 'xgv ', '2.4', '55%'),|
|  ('1008', '-21', 'qeg', '2.8', '135%'),|
|  ('1009', '-99', 'ali', '3.2', '191%'),|
|  ('1010', '-71', 'jtj ', '3.6', '25%');|
||
|COMMIT;|
||
END
      end
    end
  end
end

