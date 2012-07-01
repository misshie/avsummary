require 'avconfig'

class AvSummary
  attr_reader :dsl

  def parse_config(&block)
    $dsl = AvConfig.new.instance_eval(&block)
  end

  def proc_code(code)
    Proc.new {eval(code)}
  end

  def proc_file(file)
    proc_code(file.read)
  end

  def parse_config_file(file)
    parse_config(proc_file(file))
  end
end

