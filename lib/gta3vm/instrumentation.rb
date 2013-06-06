require "benchmark"
module Instrumentation
  class << self
    cattr_accessor :instrumenting
    cattr_accessor :instrumentation
  end

  def self.instrument(&block)
    self.instrumentation = Hash.new { |h, k| h[k] = Array.new }
    self.instrumenting = true
    return yield
  ensure
    self.instrumentation.each_pair do |key,values|
      avg = values.reduce(:+).to_f / values.size
      puts "#{key}: #{avg} - #{values.inspect}"
    end
    self.instrumenting = false
  end

  def self.time_block(label,&block)
    return yield unless self.instrumenting
    result = nil
    Benchmark.bm { |x|
      self.instrumentation[label] << x.report{
        result = yield
      }.real
    }
    result
  end

end
