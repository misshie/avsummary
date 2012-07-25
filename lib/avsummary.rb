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
  VCF_HEADER =
    %w(#CHROM POS ID REF ALT QUAL FILTER INFO FORMAT sample).join("\t")

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

    def snv_summary(arg=nil)
      arg ? @snv_summary = arg : (@snv_summary ||= "summary_snv.txt")
    end

    def indel_dir(arg=nil)
      arg ? @indel_dir = arg : (@indel_dir ||= "INDEL")
    end

    def indel_summary(arg=nil)
      arg ? @indel_summary = arg : (@indel_summary ||= "indel_snv.txt")
    end

    def convert2annovar(arg=nil)
      arg ? @convert2annovar = arg : @convert2annovar
    end
  end

  class Annotation
    attr_reader :name

    def initialize(arg)
      @name = arg
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

    def buildver(arg=nil)
      arg ? @buildver = arg : @buildver
    end

    def dbtype(arg=nil)
      arg ? @dbtype = arg : @dbtype
    end

    def avopt(arg=nil)
      arg ? @avopt = arg : @avopt
    end

    def info_col(arg=nil)
      arg ? @info_col = arg : @info_col
    end

    def info_header(arg=nil)
      arg ? @info_header = arg : (@info_header ||= @name)
    end

    def vcf_col(arg=nil)
      arg ? @vcf_col = arg : @vcf_col
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
    
    def annotation(name, &block)
      annot = Annotation.new(name)
      annot.instance_eval(&block)
      @annotations ||= Array.new
      if @annotations.any?{|x|x.name == annot.name}
        $stderr.puts "[ERROR] annotations name must be UNIQUE in an avconfig file"
        raise
      end
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
                   "--includeinfo",
                   "--allallele",
                   config.source.snv_vcf,
                   "> #{config.source.snv_av}",
                   "2> #{config.source.snv_av}.log",
                   ].join(" ").squeeze(" ")
        fout.puts "# INDEL"
        fout.puts ["${cmd}",
                   "--format vcf4",
                   "--includeinfo",
                   "--allallele",
                   config.source.indel_vcf,
                   "> #{config.source.indel_av}",
                   "2> #{config.source.indel_av}.log",
                   ].join(" ").squeeze(" ")
      end

      open(AVSCRIPT, 'w') do |fout|
        fout.puts "#!/bin/bash"
        fout.puts "cmd=\"#{config.source.annotate_variation}\""
        fout.puts "db=\"#{config.source.database_dir}\""
        fout.puts "# SNV"
        fout.puts "mkdir -p #{config.source.snv_dir}"
        config.annotations.each_with_index do |annot|
          if annot.type.include? :snv
            fout.puts ["${cmd}",
                       "--outfile #{config.source.snv_dir}/#{annot.name}",
                       "--#{annot.mode}",
                       "--buildver #{annot.buildver}",
                       "--dbtype #{annot.dbtype}",
                       "#{annot.avopt}",
                       "#{config.source.snv_av}",
                       "${db}",
                       "2> #{config.source.snv_dir}/#{annot.name}.log",
                      ].join(" ").squeeze(" ")
          end
        end
        fout.puts "# INDEL"
        fout.puts "mkdir -p #{config.source.indel_dir}"
        config.annotations.each do |annot|
          if annot.type.include? :indel
            fout.puts ["${cmd}",
                       "--outfile #{config.source.indel_dir}/#{annot.name}",
                       "--#{annot.mode}",
                       "--buildver #{annot.buildver}",
                       "--dbtype #{annot.dbtype}",
                       "#{annot.avopt}",
                       "#{config.source.indel_av}",
                       "${db}",
                       "2> #{config.source.snv_dir}/#{annot.name}.log",
                      ].join(" ").squeeze(" ")
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
        integrate_vcfs_annots
      ensure
        self.vcf_dbs ||= Hash.new
        vcf_dbs.each_value{|v|v.close}
        self.annot_dbs ||= Hash.new
        annot_dbs.each_value{|va|va.each_value{|vb|vb.close}}
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
      self.vcf_dbs ||= Hash.new
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
      self.annot_dbs ||= Hash.new
      config.annotations.each do |annot|
        $stderr.puts "[avsummary integrate] - #{annot.name} annotation(s)"
        db = Hash.new
        if annot.type.include? :snv
          db[:snv] = KyotoCabinet::DB.new
          db[:snv].open
          store_an_annot(db, config.source, annot, :snv)
        end
        if annot.type.include? :indel
          db[:indel] = KyotoCabinet::DB.new
          db[:indel].open
          store_an_annot(db, config.source, annot, :indel)
        end
        self.annot_dbs[annot.name] = db          
      end
    end

    def store_an_annot(db, source, annot, type)
      open(annot_filename(source, annot, type), "r") do |fin|
        fin.lines.each do |row|
          cols = row.chomp.split("\t")
          vcfcol = parse_vcf_row(cols[annot.vcf_col..-1].join("\t"))
          key = "#{vcfcol.chrom}:#{vcfcol.pos}"
          value = cols.values_at(annot.info_col).join("\t")
          if db[type][key]
            db[type][key] = "#{db[key]}\n#{value}"
          else
            db[type][key] = value
          end          
        end
      end
    end

    def annot_filename(source, annot, type)
      case type
      when :snv
        dir = source.snv_dir
      when :indel
        dir = source.indel_dir
      else
        raise "this should not happen"
      end

      case annot.dbtype.downcase
      when "cytoband"
        return "#{dir}/#{annot.name}.#{annot.buildver}_cytoBand"
      else
        raise "the dbtype #{source.dbtype} is not supported"
      end
    end

    def build_info_header(type)
      case type
      when :snv
        return config.annotations.
          select{|x|x.type.include?(:snv)}.
          map{|x|x.info_header}.
          flatten.join("\t")
      when :indel
        return config.annotations.
          select{|x|x.type.include?(:indel)}.
          map{|x|x.info_header}.
          flatten.join("\t")
      end
    end

    def sorted_vcf_keys(type)
      @sorted_vcf_keys ||= Hash.new
      unless @sorted_vcf_keys[type]
        keys = Array.new
        vcf_dbs[type].each_key{|k|keys << k.first}
        @sorted_vcf_keys[type] = keys.sort_by do |k|
          chr, pos = k.split(":")
          [VCF_ORDER.index(chr), Integer(pos)]
        end
      end
      @sorted_vcf_keys[type]
    end

    def integrate_vcfs_annots
      if source.snv_vcf
        open(config.source.snv_summary, "w") do |fsnv|
          fsnv.puts "#{VCF_HEADER}\t#{build_info_header(:snv)}"
          sorted_vcf_keys(:snv).each do |key|
            values = Array.new
            values << vcf_dbs[:snv][key]
            config.annotations.each do |annot|
              values << annot_dbs[annot.name][:snv]
            end
            fsnv.puts values.join("\t")
          end
        end
      end
      
      if source.indel_vcf
        open(config.source.indel_summary, "w") do |findel|
          findel.puts "#{VCF_HEADER}\t#{build_info_header(:indel)}"
        end
      end
    end

    def generate_awk_templates(snv_db, indel_db)
      #
    end
  end
end

if __FILE__ == $0 
  AvSummary::Application.start
end
