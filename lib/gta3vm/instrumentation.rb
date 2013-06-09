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
      sum = values.reduce(:+).to_f
      avg = sum / values.size
      puts "#{key}: #{sum} (avg: #{avg}}"
    end
    self.instrumenting = false
  end

  def self.time_block(label,&block)
    return yield unless self.instrumenting
    result = nil
    self.instrumentation[label] << Benchmark.measure { |x|
      result = yield
    }.real
    result
  end

end
