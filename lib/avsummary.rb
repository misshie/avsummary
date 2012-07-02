#!/bin/env ruby

require 'thor'
require 'pp'

module AvSummary
  class Source
    def snv(arg=nil)
      arg ? @snv = arg : @snv
    end

    def indel(arg=nil)
      arg ? @indel = arg : @indel
    end
  end

  class Table
    attr_reader :title

    def initialize(arg)
      @title = arg
    end

    def mode(arg=nil)
      arg ? @mode = arg : @mode
    end

    def avopt(arg=nil)
      arg ? @avopt = arg : @avopt
    end

    def chrom_col(arg=nil)
      arg ? @chrom_col = arg : @chrom_col
    end

    def start_col(arg=nil)
      arg ? @start_col = arg : @start_col
    end

    def end_col(arg=nil)
      arg ? @end_col = arg : @end_col
    end
   end

  class Config
    
  end

  class Apprication < Thor
    desc 'load', "load 'avconfig'"
    def load
      
    end
  end

end

include AvSummary

# def source(&block)
#   @source = Source.new
#   @source.instance_eval(&block)
# end

# def table(title, &block)
#   tab = Table.new(title)
#   tab.instance_eval(&block)
#   @tables ||= Array.new
#   @tables << tab
# end

if __FILE__ == $0 
  load './avconfig'
  Apprication.start
end

