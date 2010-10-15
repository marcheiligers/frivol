# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{frivol}
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Marc Heiligers"]
  s.date = %q{2010-10-15}
  s.description = %q{Simple Redis backed temporary storage intended primarily for use with ActiveRecord models to provide caching}
  s.email = %q{marc@eternal.co.za}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
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
     "doc/classes/Frivol/ClassMethods.html",
     "doc/classes/Frivol/ClassMethods.src/M000007.html",
     "doc/classes/Frivol/ClassMethods.src/M000008.html",
     "doc/classes/Frivol/ClassMethods.src/M000009.html",
     "doc/classes/Frivol/ClassMethods.src/M000010.html",
     "doc/classes/Frivol/Config.html",
     "doc/classes/Frivol/Config.src/M000009.html",
     "doc/classes/Frivol/Config.src/M000010.html",
     "doc/classes/Frivol/Config.src/M000011.html",
     "doc/classes/Frivol/Config.src/M000012.html",
     "doc/classes/Frivol/Config.src/M000013.html",
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
     "test/fake_redis.rb",
     "test/helper.rb",
     "test/test_frivol.rb"
  ]
  s.homepage = %q{http://github.com/marcheiligers/frivol}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Simple Redis backed temporary storage}
  s.test_files = [
    "test/fake_redis.rb",
     "test/helper.rb",
     "test/test_frivol.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<redis>, [">= 2.0.10"])
      s.add_development_dependency(%q<shoulda>, [">= 2.11.1"])
    else
      s.add_dependency(%q<json>, [">= 1.2.0"])
      s.add_dependency(%q<redis>, [">= 2.0.10"])
      s.add_dependency(%q<shoulda>, [">= 2.11.1"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.2.0"])
    s.add_dependency(%q<redis>, [">= 2.0.10"])
    s.add_dependency(%q<shoulda>, [">= 2.11.1"])
  end
end
