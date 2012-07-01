require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe "AvSummary" do

  context "#parse_config" do
    context "given a DSL block 'version'" do
      it "returns 'v1.0" do
        o = AvSummary.new.parse_config do
          version
        end
        o.should == "v1.0"
      end
    end
  end

  context "#proc_code" do
    context "given a code in a string [puts 'hoge']" do
      it "returns a Proc object" do
        o = AvSummary.new.proc_code('puts "hoge"')
        o.should be_a_kind_of(Proc)
      end
    end

    context "given a code in a string [true]" do
      it "return.call is true" do
        o = AvSummary.new.proc_code('true')
        o.should be_true
      end
    end  
  end

  context "#proc_file" do
    context "given a file object for a text [true]" do
      it "return.call is true" do
        o = AvSummary.new.proc_file(StringIO.new('true'))
        o.should be_true
      end
    end  
  end

  # context "#parse_config_file" do
  #   context "given a file object for a text [version]" do
  #     it "return.call is 'v1.0'" do
  #       o = AvSummary.new.parse_config_file(StringIO.new('version'))
  #       o.should == "v1.0"
  #     end
  #   end
  # end

end
