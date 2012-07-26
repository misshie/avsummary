#!/bin/env ruby

require 'thor'
require 'kyotocabinet'
require 'striuct'
require 'pp'

VERSION = "20120726"

module AvSummary
  AVCONFIG = "avconfig"
  AVCONVERT = "run-convert2annovar.sh"
  AVSCRIPT = "run-annotate-variartion.sh"
  CHR_ORDER =
    %w(M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y) \
    .map{|e|"chr#{e}"}
  AV_HEADER =
    %w(#key av_chr av_start av_end av_ref av_alt 
       CHROM POS ID REF ALT QUAL FILTER INFO FORMAT sample).join("\t")

  AvRow = Striuct.define do
    member :key, String # a key value for hash DB
    member :av_chrom, String
    member :av_start, Integer
    member :av_end, Integer
    member :av_ref, String
    member :av_alt, String
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
    def buildver(arg=nil)
      arg ? @buildver = arg : @buildver
    end

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

    def snv_awk(arg=nil)
      arg ? @snv_awk = arg : (@snv_awk ||= "filter-template-snv.awk")
    end

    def indel_dir(arg=nil)
      arg ? @indel_dir = arg : (@indel_dir ||= "INDEL")
    end

    def indel_summary(arg=nil)
      arg ? @indel_summary = arg : (@indel_summary ||= "summary_indel.txt")
    end

    def indel_awk(arg=nil)
      arg ? @indel_awk = arg : (@snv_awk ||= "filter-template-indel.awk")
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

    def dbtype(arg=nil)
      arg ? @dbtype = arg : @dbtype
    end

    def avopt(arg=nil)
      arg ? @avopt = arg : @avopt
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
                       "--buildver #{config.source.buildver}",
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
                       "--buildver #{config.source.buildver}",
                       "--dbtype #{annot.dbtype}",
                       "#{annot.avopt}",
                       "#{config.source.indel_av}",
                       "${db}",
                       "2> #{config.source.snv_dir}/#{annot.name}.log",
                      ].join(" ").squeeze(" ")
          end
        end
      end
      $stderr.puts
      $stderr.puts "Done. Run '. run-convert2annovar.sh',"
      $stderr.puts "run '. run-annotate-variation.sh', then"
      $stderr.puts "run avsummary.rb with i (integrate) command"
      $stderr.puts
    end

    desc 'integrate', 'integrate multiple annotate-variation results'
    def integrate
      begin
        $stderr.puts "[avsummary integrate] loading converted ANNOVAR input file(s)" 
        store_avfiles
        $stderr.puts "[avsummary integrate] loading annotation(s)"
        store_annots
        integrate_annots
        generate_awk_templates
      ensure
        self.av_dbs ||= Hash.new
        av_dbs.each_value{|v|v.close}
        self.annot_dbs ||= Hash.new
        annot_dbs.each_value{|va|va.each_value{|vb|vb.close}}
      end
    end   
    
    private 

    attr_accessor :av_dbs
    attr_accessor :annot_dbs

    def config
      unless @config
        if File.exist? "./#{AVCONFIG}"
          @config = 
            Config.new.instance_eval(File.read("./#{AVCONFIG}"),
                                     "./#{AVCONFIG}")
        else
          @config = 
            Config.new.instance_eval(File.read("#{File.dirname(__FILE__)}/#{AVCONFIG}"),
                                     "#{File.dirname(__FILE__)}/#{AVCONFIG}")
        end
      end
      @config
    end

    def parse_av_row(row)
      av = AvRow.new
      row.chomp!
      return nil if row.start_with? "#"
      cols = row.split("\t")
      av = AvRow.new
      av.av_chrom  = cols[0]
      av.av_start  = Integer(cols[1])
      av.av_end    = Integer(cols[2])
      av.av_ref    = cols[3]
      av.av_alt    = cols[4]
      av.chrom     = cols[5]
      av.pos       = Integer(cols[6])
      av.id        = cols[7]
      av.ref       = cols[8]
      av.alt       = cols[9]
      av.qual      = Float(cols[10])
      av.filter    = cols[11]
      av.info      = cols[12]
      av.gt_format = cols[13]
      av.genotypes = cols[14..-1]
      av.key = "#{av.av_chrom}:#{av.av_start}-#{av.av_end};#{av.av_ref}>#{av.av_alt}"
      av
    end

    def store_avfiles
      self.av_dbs = Hash.new
      load_targets = Hash.new
      if config.source.snv_av
        self.av_dbs[:snv] = KyotoCabinet::DB.new
        av_dbs[:snv].open("*")
        load_targets[:snv] = 
          {:fname => config.source.snv_av, :db =>av_dbs[:snv]} 
      end
      if config.source.indel_av
        self.av_dbs[:indel] = KyotoCabinet::DB.new
        av_dbs[:indel].open("*")
        load_targets[:indel] = 
          {:fname => config.source.indel_av, :db =>av_dbs[:indel]} 
      end

      load_targets.each do |type, fname_db|
        open(fname_db[:fname], 'r') do |fin|
          fin.each_line do |row|
            row.chomp!
            avrow = parse_av_row(row)
            if fname_db[:db][avrow.key]
              fname_db[:db][avrow.key] = "#{fname_db[:db][avrow.key]}\n#{row}"
            else
              fname_db[:db][avrow.key] = row
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
        case annot.mode.downcase
        when :regionanno, :filter
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
        when :geneanno
          if annot.type.include? :snv
            db[:snv_vf] = KyotoCabinet::DB.new
            db[:snv_vf].open
            store_an_annot(db, config.source, annot, :snv_vf)
            db[:snv_evf] = KyotoCabinet::DB.new
            db[:snv_evf].open
            store_an_annot(db, config.source, annot, :snv_evf)
          end
          if annot.type.include? :indel
            db[:indel_vf] = KyotoCabinet::DB.new
            db[:indel_vf].open
            store_an_annot(db, config.source, annot, :indel_vf)
            db[:indel_evf] = KyotoCabinet::DB.new
            db[:indel_evf].open
            store_an_annot(db, config.source, annot, :indel_evf)
          end
          self.annot_dbs[annot.name] = db          
        end
      end
    end

    def store_an_annot(db, source, annot, type)
      case annot.mode.downcase
      when :regionanno, :filter
        open(annot_filename(source, annot, type), "r") do |fin|
          fin.lines.each do |row|
            cols = row.chomp.split("\t")
            key = "#{cols[2]}:#{cols[3]}-#{cols[4]};#{cols[5]}>#{cols[6]}"
            value = cols[1]
            if db[type][key]
              raise "duplicated key in '#{annot.name}/#{type}' is found!"
              #db[type][key] = "#{db[key]}\n#{value}"
            else
              db[type][key] = value
            end
          end # lines.each
        end # open
      when :geneanno
        open(annot_filename(source, annot, type), "r") do |fin|
          fin.lines.each do |row|
            cols = row.chomp.split("\t")
            case type
            when :snv_vf, :indel_vf
              key = "#{cols[2]}:#{cols[3]}-#{cols[4]};#{cols[5]}>#{cols[6]}"
              value = "#{cols[0]}\t#{cols[1]}"
            when :snv_evf, :indel_evf
              key = "#{cols[3]}:#{cols[4]}-#{cols[5]};#{cols[6]}>#{cols[7]}"
              value = "#{cols[1]}\t#{cols[2]}"
            end
             if db[type][key]
               raise "duplicated key in '#{annot.name}/#{type}' is found!"
               #db[type][key] = "#{db[key]}\n#{value}"
             else
               db[type][key] = value
             end
          end # lines.each
        end # open
      else
        raise "the mode '#{annot.dbtype}' is not supported"
      end
    end

    def annot_filename(source, annot, type)
      case type
      when :snv, :snv_vf, :snv_evf
        dir = source.snv_dir
      when :indel, :indel_vf, :indel_evf
        dir = source.indel_dir
      else
        raise "this should not happen"
      end

      case annot.mode.downcase
      when :geneanno
        case type
        when :snv_vf, :indel_vf
          return Dir["#{dir}/#{annot.name}.variant_function"].first
        when :snv_evf, :indel_evf
          return Dir["#{dir}/#{annot.name}.exonic_variant_function"].first
        end
      when :regionanno
        return Dir["#{dir}/#{annot.name}.#{config.source.buildver}_*"].first
      when :filter
        return Dir["#{dir}/#{annot.name}.#{config.source.buildver}_*_dropped"].first
      else
        raise "the mode '#{annot.dbtype}' is not supported"
      end
    end

    def build_info_header(type)
      fields = Array.new
      config.annotations.select{|x|x.type.include?(type)}.each do |annot|
        case annot.mode
        when :regionanno, :filter
          fields << annot.name
        when :geneanno
          fields << "#{annot.name}:var_func" << "#{annot.name}:exon_var_func"
        end
      end
      fields.join("\t")
    end

    def sorted_vcf_keys(type)
      @sorted_vcf_keys ||= Hash.new
      unless @sorted_vcf_keys[type]
        keys = Array.new
        av_dbs[type].each_key{|k|keys << k.first}
        @sorted_vcf_keys[type] = keys.sort_by do |k|
          chr, st, ed, ref, alt = k.split(/:|-|;|>/)
          [CHR_ORDER.index(chr), Integer(st), Integer(ed), ref, alt]
        end
      end
      @sorted_vcf_keys[type]
    end

    def integrate_annots
      types = Array.new
      wfile = Hash.new
      if config.source.snv_vcf
        types << :snv
        wfile[:snv] = config.source.snv_summary
      end
      if config.source.indel_vcf
        types << :indel 
        wfile[:indel] = config.source.indel_summary
      end
 
      types.each do |type|
        open(wfile[type], "w") do |fsnv|
          fsnv.puts "#{AV_HEADER}\t#{build_info_header(type)}"
          sorted_vcf_keys(type).each do |key|
            values = Array.new
            values << key
            values << av_dbs[type][key]
            config.annotations.each do |annot|
              case annot.mode.downcase
              when :regionanno, :filter
                hit = annot_dbs[annot.name][type][key]
                if hit
                  values << hit
                else 
                  values << "none"
                end
              when :geneanno
                hit_vf  = annot_dbs[annot.name]["#{type}_vf".to_sym][key]
                if hit_vf
                  values << hit_vf
                else
                  values << "none" << "none"
                end
                hit_evf = annot_dbs[annot.name]["#{type}_evf".to_sym][key]
                if hit_evf
                  values << hit_evf
                else
                  values << "none" << "none"
                end
              else
                raise "this should not happen"
              end
            end
            fsnv.puts values.join("\t")
          end
        end
      end
    end

    def generate_awk_templates
      $stderr.puts "[avsummary integrate] generate awk template(s)" 
      types = Array.new
      wfilename = Hash.new
      if config.source.snv_vcf
        types << :snv 
        wfilename[:snv] = config.source.snv_awk
      end
      if config.source.indel_vcf
        types << :indel
        wfilename[:indel] = config.source.indel_awk
      end
      types.each do |type|
        open(wfilename[type], 'w') do |fout|
          fout.puts '#!/bin/awk'
          fout.puts "BEGIN {"
          colcount = AV_HEADER.split("\t").size + 1
          config.annotations.select{|x|x.type.include?(type)}.each do |annot|
            case annot.mode
            when :regionanno, :filter
              fout.puts %!col["#{annot.name}"]=#{colcount}!
              colcount += 1                               
            when :geneanno
              fout.puts %!col["#{annot.name}_vf"]=#{colcount}!
              colcount += 1
              fout.puts %!col["#{annot.name}_evf"]=#{colcount}!
              colcount += 1
            end
          end
          fout.puts "}"
        end # open
      end # types.each
    end # def
  end # class Apprication
end # module AvSummary

if __FILE__ == $0 
  AvSummary::Application.start
end
