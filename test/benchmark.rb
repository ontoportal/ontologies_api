require_relative 'test_case'
require "benchmark"

class TestBenchmarkCode < TestCase
  def test_benchmark_code
    time = Benchmark.measure do
      25.times do
        get "/ontologies"
      end
    end

    puts "get all onts:"
    puts time
  end
end