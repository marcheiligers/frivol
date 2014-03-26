require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "frivol"
    gem.summary = %Q{Simple Redis backed temporary storage}
    gem.description = %Q{Simple Redis backed temporary storage intended primarily for use with ActiveRecord models to provide caching}
    gem.email = "marc@eternal.co.za"
    gem.homepage = "http://github.com/marcheiligers/frivol"
    gem.authors = ["Marc Heiligers"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

namespace :test do
  desc 'Test all backends and the Multi backend in all combinations'
  task :all do
    %w[
      fake_redis redis redis_distributed riak multi
      multi_redis_redis multi_redis_redis_distributed
      multi_redis_riak multi_redis_distributed_riak
      multi_riak_redis multi_riak_redis_distributed
    ].each do |backend|
      puts "Testing #{backend}"
      ENV['backend'] = backend
      Rake::Task["test"].reenable
      Rake::Task["test"].invoke
    end
  end
end

task :default => :test

begin
  require 'rdoc/task'
  Rake::RDocTask.new do |rdoc|
    version = File.exist?('VERSION') ? File.read('VERSION') : ""

    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "frivol #{version}"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError, RuntimeError => e
  if e.is_a?(LoadError) || (e.is_a?(RuntimeError) && e.message.start_with?("ERROR: 'rake/rdoctask'"))
    puts "RDocTask (or a dependency) not available. Maybe older Ruby?"
  else
    raise e
  end
end
