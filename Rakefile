require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'
# require 'metric_fu'
# require 'yard'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :test do
  desc 'Measures test coverage'
  task :coverage do
    rm_f "coverage"
    rm_f "coverage.data"
    rcov = "rcov --aggregate coverage.data --text-summary --exclude test,^/"
    system("#{rcov} --html test/*_spec.rb")
  end
end

def flog(output, *directories)
  system("find #{directories.join(" ")} -name \\*.rb | xargs flog")
end

desc "Analyze code complexity."
task :flog do
  flog "lib", "lib"
end

desc "rdoc"
Rake::RDocTask.new('rdoc') do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = 'Virginity vCard library'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.main = 'README'
  rdoc.rdoc_files.include('README', "lib/**/*.rb")
end


#YARD::Rake::YardocTask.new do |yardoc|
#  yardoc.files   = ['lib/**/*.rb', 'README', 'objectives']
#  yardoc.options = ['--any', '--extra', '--opts'] # optional
#end


gem_spec = eval(File.read('virginity.gemspec'))
Gem::PackageTask.new(gem_spec) do |pkg|
  pkg.need_tar_bz2 = true
  pkg.need_zip = true
  pkg.need_tar = true
end

