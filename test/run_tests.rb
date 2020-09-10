gem_dir = Gem::Specification.find_by_name('ontologies_linked_data').gem_dir
require "#{gem_dir}/test/run_tests"
