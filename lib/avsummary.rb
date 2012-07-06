#!/bin/env ruby

require 'thor'
require 'kyotocabinet'
require 'pp'


module AvSummary
  AVCONFIG = "avconfig"
  AVSCRIPT = "run-annotate-variartion.sh"
  VCF_ORDER =
    %w(M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y) \
    .map{|e|"chr#{e}"}

  class Source
    def snv_vcf(arg=nil)
      arg ? @snv_vcf = arg : @snv
    end

    def snv_av(arg=nil)
      arg ? @snv_av = arg : @snv
    end

    def indel_vcf(arg=nil)
      arg ? @indel_vcf = arg : @indel
    end

    def indel_av(arg=nil)
      arg ? @indel_av = arg : @indel
    end

    def annotate_variation(arg=nil)
      arg ? @annotate_variation = arg : @annotate_variation 
    end

    def database_dir(arg=nil)
      arg ? @database_dir = arg : @database_dir
    end
  end

  class Table
    attr_reader :title

    def initialize(arg)
      @title = arg
    end

    def type(*arg)
      if arg.empty?
        @type
      else
        @type = arg
      end
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
    attr_reader :tables

     def source(&block)
      if block_given?
        @source = Source.new
        @source.instance_eval(&block)
        self
      else
        @source
      end
    end
    
    def table(title, &block)
      tab = Table.new(title)
      tab.instance_eval(&block)
      @tables ||= Array.new
      @tables << tab
      self
    end    
  end

  class Apprication < Thor
    include AvSummary

    desc 'annotate', 'generate a annotate_variation script'
    def annotate


      open(AVSCRIPT, 'w') do |fout|
        fout.puts "#!/bin/sh"
        fout.puts "cmd=\"#{config.source.annotate_variation}\""
        fout.puts "db=\"#{config.source.database_dir}\""
        fout.puts "# SNV"
        config.tables.each_with_index do |tab|
          if tab.type.include? :snv
            fout.puts ["${cmd}",
                       "--outfile #{tab.title}",
                       "--#{tab.mode}",
                       "#{tab.avopt}",
                       "#{config.source.snv_av}",
                       "${db}",
                      ].join(" ")
          end
        end
        fout.puts "# INDEL"
        config.tables.each do |tab|
          if tab.type.include? :indel
            fout.puts ["${cmd}",
                       "--outfile #{tab.title}",
                       "--#{tab.mode}",
                       "#{tab.avopt}",
                       "#{config.source.indel_av}",
                       "${db}",
                      ].join(" ")
          end
        end
      end
    end

    desc 'integrate', 'integrate multiple annotate-variation results'
    def intgrate
      load_vcf
      load_tables
      integrate_tables
      generate_awk_template
    end

    private 

    def config
      @config ||= 
        Config.new.instance_eval(File.read("#{File.dirname(__FILE__)}/#{AVCONFIG}"))
    end

  #   def load_filter(file)
      
  #   end
  end

end

if __FILE__ == $0 
  AvSummary::Apprication.start
end
