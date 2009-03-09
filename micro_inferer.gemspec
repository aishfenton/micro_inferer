Gem::Specification.new do |s|
  s.name = "micro_inferer"
  s.version = '0.1.3'
  s.authors = ["VisFleet"]
  s.homepage = ["labs.visfleet.com/micro_inferer"]
  s.date = '2009-01-01'
  s.email = "lab-info@visfleet.com"
  s.files = [
             "lib/conditions_tree.rb",
             "lib/micro_inferer.rb",
             "README.rdoc",
             "spec/conditions_tree_spec.rb", 
             "spec/inferer_spec.rb", 
             "spec/rule_spec.rb", 
             "perf_test/scenario1.rb", 
             "perf_test/scenario2.rb", 
            ]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.require_paths = ["lib"]
  s.description = "A micro inference engine"
  s.summary = <<-EOF
    A micro inference engine. Specify rules in a DSL and have facts inferered from them
    for you.
  EOF
end