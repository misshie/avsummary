require 'rspec'
require 'stringio'

# this method is written by wycats
# http://d.hatena.ne.jp/POCHI_BLACK/20100324/1269413263

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end

  result
end
