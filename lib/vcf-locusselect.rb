#!/bin/env ruby

require 'kyotocabinet'
require 'striuct'

class VcfLocusSelect
  VERSION = "20121127"

  attr_accessor :db

  def load_original(fin)
    @db = KyotoCabinet::DB.new
    db.open("*") # on-memory DB
    fin.lines.each do |row|
      row.chomp!
      if row.start_with? '#'
        puts row
        next
      end
      cols = row.split("\t")
      key = "#{cols[0]}:#{cols[1]}"
      if db[key]
        $stderr.puts "duplicated position: #{key}, only the 1st record is to be stored"
      else
        db[key] = row
      end
    end
  end

  def load_loci(fin)
    fin.lines.each do |row|
      row.chomp!
      next if row.start_with? '#'
      cols = row.split("\t")
      key = "#{cols[0]}:#{cols[1]}"
      hit = db[key]
      if hit
        puts hit
      else
        $stderr.puts "missing key: #{key}"
      end
    end
  end

  def run
    $stderr.puts "Loading original VCF file..."
    open(ARGV[0], 'r') do |fin|
      load_original(fin)
    end

    $stderr.puts "Start locus search..."
    open(ARGV[1], 'r') do |fin|
      load_loci(fin)
    end
  end
end

if __FILE__ == $0
  if ARGV.size == 0 || ["-h", "-help", "--help"].any?{|x|x == ARGV[0]}
    $stderr.puts "Usage:"
    $stderr.puts "#$0 <original VCF> <locus-to-be-chosen VCF>"
    exit(1)
  end
  VcfLocusSelect.new.run
end
