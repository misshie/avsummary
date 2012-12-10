#!/usr/bin/env ruby

require 'optparse'

#Version = "20111228b"
#Version = "20111230c"
#Version = "20120102"
#Version = "20120117"
#Version = "20120528"
#Version = "20120906 (renamed from geneint.rb into genewise.rb)"
#Version = "20121025"
Version = "20121104" # count only non REF alleles

class GenewiseHash
  def initialize(opts)
    @conversion = Hash.new
    @ghash = Hash.new
    @col_varfunc   = opts[:genedb] - 1 + 0
    @col_gene      = opts[:genedb] - 1 + 1
    @col_exvarfunc = opts[:genedb] - 1 + 2
    @col_exon      = opts[:genedb] - 1 + 3
  end

  attr_reader :col_varfunc, :col_gene, :col_exvarfunc, :col_exon 
  attr_reader :conversion
  attr_accessor :ghash

  def add(row, sample)
    cols = row.chomp.split("\t")
    if cols[col_varfunc] == "intergenic"
      $stderr.puts "warning (intergenic in selected gene prediction): #{row}"
      return false
    end

    row = "#{sample}\t#{row}"
    gene = cols[col_gene]
    gene = gene.split(";").first
    gene = gene.split("(").first
    if gene.include?(",")
      (@ghash[gene.gsub(",","-")] ||= []) << row
    else
      if @conversion[gene]
        (@ghash[@conversion[gene]] ||= []) << row
      else
        (@ghash[gene] ||= []) << row
      end
    end
    @ghash
  end

  def build_conversion(file)
    file.readlines.each do |row|
      next if row.start_with? "#"
      gene = row.chomp.split("\t")[col_gene]

      if gene.include?(",")
        gene.split(",").each do |subgene|
          @conversion[subgene] = gene.gsub(",","-")
        end
      end
    end
    @conversion
  end

end

class GeneWise
  VCF_ORDER =
    %w(M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y).
    map{|e|"chr#{e}"}
  INFO_ORDER = %w(SG SL FS SP IF UK OO NS)

  def initialize(opts)
    @opts = opts
    @col_varfunc   = opts[:genedb] - 1 + 0
    @col_gene      = opts[:genedb] - 1 + 1
    @col_exvarfunc = opts[:genedb] - 1 + 2
    @col_exon      = opts[:genedb] - 1 + 3
    @genotype      = opts[:genotype] - 1
    @genewise =  GenewiseHash.new(opts)
  end

  attr_reader :opts
  attr_reader :col_varfunc, :col_gene, :col_exvarfunc, :col_exon 
  attr_reader :genewise, :genotype

  def output_header
    header = nil
    open(opts[:samples].first[1], 'r') do |fin|
      open(opts[:output], 'w') do |fout|
        header = fin.gets.chomp
        if header.start_with?("#")
          header = "ensGene\tsample\t#{header.sub(/\#/,"")}"
          fout.puts header
        end
      end
    end
    header
  end
  
  def build_conversion_all
    opts[:samples].each do |sample, path|
      open(path, 'r') do |fin|
        @genewise.build_conversion fin
      end
    end
    @genewise.conversion
  end

  def add_all_loci
    opts[:samples].each do |sample, path|
      File.readlines(path).each do |row|
        row.chomp!
        unless row.start_with? "#"
          @genewise.add(row, sample)
        end
      end
    end
    @genewise.ghash
  end

  def sort
    sorted1 = Hash.new
    genewise.ghash.each do |k, v|
      sorted1[k] = v.sort_by do |row|
        cols = row.chomp.split("\t")
        # cols => [sample_name, key, av_chr, av_start, ...
        [VCF_ORDER.index(cols[2]),
         Integer(cols[3]),
         Integer(cols[4])]
      end
    end   
    ordered_key = sorted1.keys.sort_by do |key|
      cols = sorted1[key].first.chomp.split("\t")     
        [VCF_ORDER.index(cols[2]), 
         Integer(cols[3]),
         Integer(cols[4])]
    end
 
    sorted2 = Hash.new
    ordered_key.each do |key|
      sorted2[key] = sorted1[key].dup
    end
    genewise.ghash = sorted2.dup
  end

  def output_ghash
    open(opts[:output],'a') do |fout|
      genewise.ghash.each do |k, v|
        v.each do |value|
          fout.puts "#{k}\t#{value}"
        end
      end
    end
  end

  def output_summary_header
    open(opts[:summary], 'w') do |fout|
      header = Array.new
      header << "GeneID" << "uniq_loci" << "recessive" << "dominant" << "info"
      opts[:samples].keys.each do |key|
        header << "#{key}_HOM" << "#{key}_HET" << "#{key}_info"
      end
      fout.puts header.join("\t")
    end
  end

  def count_uniq_loci(rows)
    loci = Hash.new
    rows.each do |row|
      chr, first, last = row.split("\t")[1..3]
      loci["#{chr}:#{first}-#{last}"] = true
    end
    loci.length
  end

  def refhom?(alleles)
    ((alleles[0] == "0" && alleles[1] == "0") ||
     (alleles[0] == "." && alleles[0] == "."))
  end

  def count_hom_het_info(sample, rows)
    sample_rows = rows.select{|x|x.split("\t")[0] == sample}
    hom = 0
    het = 0
    info = Hash.new
    sample_rows.each do |row|
      alleles = row.split("\t")[genotype + 1].split(":")[0].split("/") 
      unless refhom?(alleles)
        if alleles[0] == alleles[1]
          hom += 1
        else
          het += 1
        end
        key = analyze_variant_info(row.split("\t")[(col_varfunc + 1)..(col_exon + 1)])
        if info[key]
          info[key] += 1
        else
          info[key] = 1
        end
      end
    end
    [hom, het, info]
  end

  def analyze_variant_info(cols)
    case
    when cols[2] =~ /nonsynonymous/
      return "NS"
    when cols[2] =~ /stopgain/
      return "SG"
    when cols[2] =~ /stoploss/
      return "SL"
    when cols[0] =~ /splicing/
      return "SP"
    when cols[2] =~ /unknown/
      return "UK"
    when cols[2] =~ /\Aframeshift/
      return "FS"
    when cols[2] =~ /\Anonframeshift/
      return "IF"
    else
      return "OO" # others
    end
  end

  def output_summary
    open(opts[:summary], 'a') do |fout|
      genewise.ghash.each do |gene, rows|
        recessive = 0
        dominant = 0
        allinfo = Hash.new
        sample_counts = Array.new
        opts[:samples].keys.each do |sample|
          hom, het, info = count_hom_het_info(sample, rows)
          recessive += 1 if (hom >= 1 || het >=2) 
          dominant += 1 if (hom >= 1 || het >= 1)
          info.each do |key, value|
            if allinfo[key]
              allinfo[key] += 1
            else
              allinfo[key] = 1
            end
          end
          info_str =
            info.sort_by{|k,v|INFO_ORDER.index(k)}.each \
            .map{|k,v|"#{k}=#{v}"}.join(";")
          info_str = "none" if info_str.empty?
          sample_counts << hom.to_s << het.to_s << info_str
        end
        output = Array.new
        output << gene
        output << count_uniq_loci(rows).to_s
        output << recessive.to_s
        output << dominant.to_s
        output << 
          allinfo.sort_by{|k,v|INFO_ORDER.index(k)}.each \
          .map{|k,v|"#{k}=#{v}"}.join(";")
        output << sample_counts.join("\t")
        fout.puts output.join("\t")
      end
    end
  end

  def run
    gh = GenewiseHash.new(opts)
    output_header
    build_conversion_all
    add_all_loci
    sort
    output_ghash
    output_summary_header
    output_summary
  end
end

if __FILE__ == $0
  opts = Hash.new
  opts[:samples] = Hash.new

  ARGV[0] = "--help" if ARGV.length == 0
  ARGV.options do |o|
    o.banner = "geneint.rb [option] <sample name>::<join-av-vcfint.rb's output file> [...]"
    o.on('-d num', '--genedb', Integer,
         "Column number of the Gene DB (GENCODE, Enseml, etc.) var_func column (1-based, default: 41)\n        *expected order: <var_func1>, <var_func2>, <exon_var_func1>, <exon_var_func2>") do |x|
      opts[:genedb] = x 
    end
    o.on('-e num', '--ensembl', Integer,
         'obsolete, use --genedb.') do |x|
      opts[:genedb] = x      
    end
    o.on('-g num', '--genotype', Integer,
         'VCF-style genotype column (1-based, default: 20)') do |x|
      opts[:genotype] = x
    end
    o.on('-o file', '--output',
         'variant table filename (required)') do |x|
      opts[:output] = x
    end
    o.on('-s file', '--summary',
         'summary table filename (required)') do |x|
      opts[:summary] = x
    end
    o.separator "    -v, --version                    show version information"
    o.separator "    -h, --help                       show this message"
    o.separator " last update: #{o.version}"
    o.parse!
  end
  opts[:genedb] ||= 41
  opts[:genotype] ||= 20

  ARGV.each do |arg|
    sample, path = arg.split("::")
    opts[:samples][sample] = path
  end

  GeneWise.new(opts).run
end
