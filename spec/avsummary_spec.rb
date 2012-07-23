require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe "AvSummary" do
  describe "Application" do

    context "#load_vcf" do
      context "given " do
        it "return" do
          o = AvSummary::Application.new
          c = AvSummary::Config.new
          c.stub_chain(:source, :snv_vcf).and_return("example/snv500.vcf")
          c.source.snv_vcf.should == "hoge"
          # o.__send__(:load_vcf)
        end
      end
    end

  end
end
