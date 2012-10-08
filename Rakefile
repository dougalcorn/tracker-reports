# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "tracker-reports"
  gem.homepage = "http://github.com/dougalcorn/tracker-reports"
  gem.license = "MIT"
  gem.summary = %Q{Reporting against Pivotal Tracker projects}
  gem.description = %Q{Primarily used to generate project summaries to include on invoices across a date range}
  gem.email = "dougalcorn@gmail.com"
  gem.authors = ["Doug Alcorn"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tracker-reports #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/tracker-reports'

desc "Accepted story summary for PROJECT_ID between START_DATE and END_DATE"
task :accepted_stories do
  options = {
    :project_id => ENV['PROJECT_ID'],
    :start_date => Date.parse(ENV['START_DATE']),
    :end_date => Date.parse(ENV['END_DATE'])
  }
  t = TrackerReports.new(options)
  puts t.story_summary
end

task :project_stories do
  options = {
    project_id: ENV['PROJECT_ID'],
    start_date: (Date.today - 14).to_s,
    end_date: Date.today.to_s,
  }
  projects = Psych.load(File.open(ENV['PROJECTS']))
  projects.each do |name, project_id|
    puts "#{name}: #{project_id}"
    t = TrackerReports.new(options.merge(project_id: project_id.to_s))
    File.open("#{name}-#{Date.today.strftime('%Y-%m-%d')}.mkd", "w") { |f| f.puts t.story_summary }
  end
end
  
