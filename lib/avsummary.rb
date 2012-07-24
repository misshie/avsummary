#!/bin/env ruby

require 'thor'
require 'kyotocabinet'
require 'striuct'
require 'pp'

VERSION = "20120723"

module AvSummary
  AVCONFIG = "avconfig"
  AVCONVERT = "run-convert2annovar.sh"
  AVSCRIPT = "run-annotate-variartion.sh"
  VCF_ORDER =
    %w(M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y) \
    .map{|e|"chr#{e}"}

  VcfRow = Striuct.define do
    member :chrom, String
    member :pos, Integer
    member :id, String
    member :ref, String
    member :alt, String
    member :qual, Float
    member :filter, String
    member :info, String
    member :gt_format, String
    member :genotypes, Array
  end

  class Source
    def snv_vcf(arg=nil)
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

    def convert2annovar(arg=nil)
      arg ? @convert2annovar = arg : @convert2annovar
    end
  end

  class Annotation
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
    attr_reader :annotations

     def source(&block)
      if block_given?
        @source = Source.new
        @source.instance_eval(&block)
        self
      else
        @source
      end
    end
    
    def annotation(title, &block)
      annot = Annotation.new(title)
      annot.instance_eval(&block)
      @annotations ||= Array.new
      @annotations << annot
      self
    end    
  end

  class Application < Thor
    include AvSummary

    desc 'annotate', 'generate a annotate_variation script'
    def annotate
      open(AVCONVERT, 'w') do |fout|
        fout.puts "#!/bin/bash"
        fout.puts "cmd=\"#{config.source.convert2annovar}\""
        fout.puts "# SNV"
        fout.puts ["${cmd}",
                   "--format vcf4",
                   "--allallele",
                   config.source.snv_vcf,
                   "> #{config.source.snv_av}",
                   "2> #{config.source.snv_av}.log",
                   ].join(" ")
        fout.puts "# INDEL"
        fout.puts ["${cmd}",
                   "--format vcf4",
                   "--allallele",
                   config.source.indel_vcf,
                   "> #{config.source.indel_av}",
                   "2> #{config.source.indel_av}.log",
                   ].join(" ")
      end

      open(AVSCRIPT, 'w') do |fout|
        fout.puts "#!/bin/bash"
        fout.puts "cmd=\"#{config.source.annotate_variation}\""
        fout.puts "db=\"#{config.source.database_dir}\""
        fout.puts "# SNV"
        fout.puts "mkdir -p #{config.source.snv_dir}"
        config.tables.each_with_index do |tab|
          if tab.type.include? :snv
            fout.puts ["${cmd}",
                       "--outfile #{config.source.snv_dir}/#{tab.title}",
                       "--#{tab.mode}",
                       "#{tab.avopt}",
                       "#{config.source.snv_av}",
                       "${db}",
                       "2> #{config.source.snv_dir}/#{tab.title}.log",
                      ].join(" ")
          end
        end
        fout.puts "# INDEL"
        fout.puts "mkdir -p #{config.source.indel_dir}"
        config.tables.each do |tab|
          if tab.type.include? :indel
            fout.puts ["${cmd}",
                       "--outfile #{config.source.indel_dir}/#{tab.title}",
                       "--#{tab.mode}",
                       "#{tab.avopt}",
                       "#{config.source.indel_av}",
                       "${db}",
                       "2> #{config.source.snv_dir}/#{tab.title}.log",
                      ].join(" ")
          end
        end
      end
    end

    desc 'integrate', 'integrate multiple annotate-variation results'
    def integrate
      begin
        $stderr.puts "[avsummary integrate] loading a vcf file" 
        store_vcfs
        $stderr.puts "[avsummary integrate] loading annotation(s)"
        store_annots
      ensure
        vcf_dbs.each{|k,v|v.close}
        annot_dbs.each{|x|x.each{|k,v|v.close}}
      end
    end   
    
    private 

    attr_accessor :vcf_dbs
    attr_accessor :annot_dbs

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

    def store_vcfs
      self.vcf_dbs = Hash.new
      self.vcf_dbs[:snv] = KyotoCabinet::DB.new
      vcf_dbs[:snv].open("*")
      self.vcf_dbs[:indel] = KyotoCabinet::DB.new
      vcf_dbs[:indel].open("*")

      [ { :vcf => config.source.snv_vcf,
          :db  => vcf_dbs[:snv]},
        { :vcf => config.source.indel_vcf,
          :db  => vcf_dbs[:indel]} ].each do |vcfdb|
        open(vcfdb[:vcf]) do |fin|
          fin.each_line do |row|
            row.chomp!
            next if row.start_with? "#"
            vcfcol = parse_vcf_row(row)
            key = "#{vcfcol.chrom}:#{vcfcol.pos}"
            if vcfdb[:db][key]
              vcfdb[:db][key] = "#{vcfdb[:db][key]}\n#{row}"
            else
              vcfdb[:db][key] = row
            end          
          end # fin.each_line
        end # open
      end # each
    end # def kc_store

    def store_annots
      self.annot_dbs = Array.new
      config.annotations.each do |annot|
        db = Hash.new
        if annot.type.include? :snv
          db[:snv] = KyotoCabinet::DB.new
          db[:snv].open
        end
        if annot.type.include? :indel
          db[:indel] = KyotoCabinet::DB.new
          db[:indel].open
        end
        self.annot_dbs << db          
      end
    end

    def load_table(snv_db, indel_db)
      
    end
    
    def integrate_tables(snv_db, indel_db)
      #
    end

    def generate_awk_templates(snv_db, indel_db)
      #
    end
  end
end

if __FILE__ == $0 
  AvSummary::Application.start
end
