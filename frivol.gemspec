# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: frivol 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "frivol"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Marc Heiligers"]
  s.date = "2014-03-06"
  s.description = "Simple Redis backed temporary storage intended primarily for use with ActiveRecord models to provide caching"
  s.email = "marc@eternal.co.za"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".travis.yml",
    "Gemfile",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "doc/classes/Frivol.html",
    "doc/classes/Frivol.src/M000003.html",
    "doc/classes/Frivol.src/M000004.html",
    "doc/classes/Frivol.src/M000005.html",
    "doc/classes/Frivol.src/M000006.html",
    "doc/classes/Frivol.src/M000007.html",
    "doc/classes/Frivol.src/M000008.html",
    "doc/classes/Frivol/ClassMethods.html",
    "doc/classes/Frivol/ClassMethods.src/M000009.html",
    "doc/classes/Frivol/ClassMethods.src/M000010.html",
    "doc/classes/Frivol/ClassMethods.src/M000011.html",
    "doc/classes/Frivol/Config.html",
    "doc/classes/Frivol/Config.src/M000012.html",
    "doc/classes/Frivol/Config.src/M000013.html",
    "doc/classes/Frivol/Config.src/M000014.html",
    "doc/classes/Time.html",
    "doc/classes/Time.src/M000001.html",
    "doc/classes/Time.src/M000002.html",
    "doc/created.rid",
    "doc/files/lib/frivol_rb.html",
    "doc/fr_class_index.html",
    "doc/fr_file_index.html",
    "doc/fr_method_index.html",
    "doc/index.html",
    "doc/rdoc-style.css",
    "frivol.gemspec",
    "lib/frivol.rb",
    "lib/frivol/class_methods.rb",
    "lib/frivol/config.rb",
    "lib/frivol/functor.rb",
    "lib/frivol/helpers.rb",
    "lib/frivol/time_extensions.rb",
    "test/fake_redis.rb",
    "test/helper.rb",
    "test/test_buckets.rb",
    "test/test_condition.rb",
    "test/test_condition_with_counters.rb",
    "test/test_counters.rb",
    "test/test_else_with_counters.rb",
    "test/test_extensions.rb",
    "test/test_frivol.rb",
    "test/test_frivolize.rb",
    "test/test_seeds.rb",
    "test/test_threads.rb"
  ]
  s.homepage = "http://github.com/marcheiligers/frivol"
  s.rubygems_version = "2.2.1"
  s.summary = "Simple Redis backed temporary storage"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multi_json>, [">= 0"])
      s.add_runtime_dependency(%q<redis>, [">= 0"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>, [">= 1.8.0"])
      s.add_runtime_dependency(%q<redis>, [">= 2.0.10"])
    else
      s.add_dependency(%q<multi_json>, [">= 0"])
      s.add_dependency(%q<redis>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<multi_json>, [">= 1.8.0"])
      s.add_dependency(%q<redis>, [">= 2.0.10"])
    end
  else
    s.add_dependency(%q<multi_json>, [">= 0"])
    s.add_dependency(%q<redis>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<multi_json>, [">= 1.8.0"])
    s.add_dependency(%q<redis>, [">= 2.0.10"])
  end
end

