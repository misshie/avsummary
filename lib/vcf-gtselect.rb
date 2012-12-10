#!/bin/env ruby

#VERSION = "20121102"
VERSION = "20121103c"

class VcfGtSelect
  attr_reader :vcffilename, :selectors, :target_col
  
  def show_version
    puts "version #{VERSION}"
  end

  def show_samples
    open(ARGV[1],'r') do |fin|
      fin.lines.each do |row|
        if row.start_with?('#CHROM')
          row.split("\t")[9..-1].each_with_index{|x,i|puts "sample ##{i+1}:#{x}"}
          break
        end
      end
    end
  end

  def show_help
    puts "commands: version, show, help, select"
    puts "select: where N is a sample number,"
    puts "tN is a _T_arget sample should not have a './.' variant."
    puts "eN is a sample should have a _E_qual variant compared to the target."
    puts "dN is a sample should have a _D_ifferent variant compared to the target."
    puts "xN is a sample should have a './.' variant." 
    puts "e.g., 't1 e2 e3 d5 x6' (these ignore sample #4)"
  end
 
  def number_of_samples(fn)
    num = 0
    open(fn, 'r') do |fin|
      fin.lines.each do |row|
        row.chomp!
        if row.start_with?('#') && !row.start_with?('##')
          return (row.split("\t").size - 9)
        end
      end
    end
  end

  def parse_opt
    @vcffilename = ARGV.pop
    @target_col = 9
    @selectors = [" "] * number_of_samples(vcffilename)
    ARGV.each do |opt|
      case opt[0]
      when 't'
        @selectors[Integer(opt[1..-1]) - 1] = 't'
        @target_col = Integer(opt[1..-1]) + 8 
      when 'd'
        @selectors[Integer(opt[1..-1]) - 1] = 'd'
      when 'e'
        @selectors[Integer(opt[1..-1]) - 1] = 'e'
      when 'x'
        @selectors[Integer(opt[1..-1]) - 1] = 'x'
      end
    end
  end

  def genotype(colstr)
    colstr.split(':')[0]
  end

  def process
    open(vcffilename, 'r') do |fin|
      fin.lines.each do |row|
        row.chomp!
        if row.start_with?('#')
          puts row
          next
        end
        process_main(row)
      end
    end
  end

  def process_main(row)
    cols = row.split("\t")
    target_gt = genotype(cols[target_col])
     explicit = selectors.each_with_index.all? {|sel,idx|
      case sel
      when 'e'
        ( target_gt == genotype(cols[9 + idx]) )
      when 'd'  
        ( target_gt != genotype(cols[9 + idx]) )
      when 'x'
        ( genotype(cols[9 + idx]) == "./.")
      when 't', ' '
        ( target_gt != "./.")
      else
        raise 'this should not happen!'
      end
    }
    # exclude = selectors.each_with_index.any? {|sel,idx|
    #   case sel
    #   when 'x', ' '
    #     false
    #   when 't', 'e', 'd'
    #     ( genotype(cols[9 + idx]) != "./." )
    #   else
    #     raise 'this should not happen!'
    #   end
    # }
    # puts row if (explicit && exclude)
    puts row if explicit
  end

  def run 
    case ARGV[0]
    when "version"
      show_version
      return
    when "show"
      show_samples
      return
    when "--help", "-h", "help"
      show_help
      return
    when "select"
      ARGV.shift
      parse_opt
      process
    end
  end

end # class
  
if __FILE__ == $0
  VcfGtSelect.new.run
end
