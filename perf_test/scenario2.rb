$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'micro_inferer'
require 'benchmark'
require 'pp'

RUNS = 50_000

@inferer = Micro::Inferer.new
@inferer.max_iterations = RUNS + 1

def setup_rules
  RUNS.times do |i|
    @inferer.when(i.to_s).then(rand().to_s)
  end
end

def assert_facts
  RUNS.times do |i|
    @inferer.assert(i.to_s)
  end
end

Benchmark.bm do |x|
  x.report("setup_rules")   { setup_rules }
  x.report("assert_facts")  { assert_facts }
  x.report("infer")         { @inferer.infer }
end
