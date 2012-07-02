require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe "AvSummary" do
  context "#" do
    context "" do
      it "return" do
        o = AvSummary.new.parse_config_file(StringIO.new('version'))
        o.dsl.should == "v1.0"
      end
    end
  end

end
