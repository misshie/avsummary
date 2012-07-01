class AvConfig
  attr_reader :snv, :indel
  attr_reader :title, :order, :mode, :avop, :chrom_col, :start_col, :end_col

  def version
    "v1.0"
  end

  def source(&block)
    self.instance_eval(&block)
  end

  def table(&block)
  #
  end
end
