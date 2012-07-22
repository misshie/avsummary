#!/bin/env ruby

require 'thor'
require 'kyotocabinet'
require 'striuct'
require 'pp'


module AvSummary
  AVCONFIG = "avconfig"
  AVSCRIPT = "run-annotate-variartion.sh"
  VCF_ORDER =
    %w(M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y) \
    .map{|e|"chr#{e}"}

  VcfRow = Striuct.define do
    member :chrom, String
    member :pos, String
    member :id, String
    member :ref, String
    member :alt, String
    member :qual, String
    member :filter, String
    member :info, String
    member :gt_format, String
    member :genotypes, Array
  end

  class Source
    def snv_vcf(arg=nil)
      @q

      arg ? @snv_vcf = arg : @snv_vcf
    end

    def snv_av(arg=nil)
      arg ? @snv_av = arg : @snv_av
    end

    def indel_vcf(arg=nil)
      arg ? @indel_vcf = arg : @indel_vcf
    end

    def indel_av(arg=nil)
      arg ? @indel_av = arg : @indel_av
    end

    def annotate_variation(arg=nil)
      arg ? @annotate_variation = arg : @annotate_variation 
    end

    def database_dir(arg=nil)
      arg ? @database_dir = arg : @database_dir
    end

    def snv_dir(arg=nil)
      arg ? @snv_dir = arg : (@snv_dir ||= "SNV")
    end

    def indel_dir(arg=nil)
      arg ? @indel_dir = arg : (@indel_dir ||= "INDEL")
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
      generate_awk_templateq
    end

    private 

    def config
      unless @config
        if File.exist? "./#{AVCONFIG}"
          @config = 
            Config.new.instance_eval(File.read("./#{AVCONFIG}"))
        else
          @config = 
            Config.new.instance_eval(File.read("#{File.dirname(__FILE__)}/#{AVCONFIG}"))
        end
      end
      @config
    end

    def parse_vcf_row(row)
      vcfrow = VcfRow.new
      row.chomp!
      return nil if row.start_with? "#"
      cols = row.split("\t")
      vcfrow = VcfRow.new
      vcfrow.chrom = cols[0]
      vcfrow.pos = Integer(cols[1])
      vcfrow.id = cols[2]
      vcfrow.ref = cols[3]
      vcfrow.alt = cols[4]
      vcfrow.qual = Float(cols[5])
      vcfrow.filter = cols[6]
      vcfrow.info = cols[7]
      vcfrow.gt_format = cols[8]
      vcfrow.genotypes = cols[9..-1]
      vcfrow   
    end

    def load_vcf
      $stderr.puts "[avsummary integrate] start loading a vcf file"
      snv_db   = KyotoCabinet::DB.new.open("*") # on-memory hash DB
      indel_db = KyotoCabinet::DB.new.open("*") # on-memory hash DB
      
      open(config.source.snv_vcf) do |fin|
        fin.each_line do |row|
          row.chomp!
          vcfcol = parse_vcf_row(row)
          key = "#{vcfcol.chrom}:#{vcfcol.pos}"
          if snv_db[key]
            snv_db[key] = "#{snv_db[key]}\n#{row}"
          else
            snv_db[key] = row
          end          
        end
      end
    end
  end

end

if __FILE__ == $0 
  AvSummary::Apprication.start
end
