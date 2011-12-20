require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--profile]
  t.pattern = 'spec/**/*_spec.rb'
end

require "distillery"
require "iconv"

def doc_for_fixture(fixture)
  file = File.join(File.dirname(__FILE__), 'spec', 'fixtures', fixture)
  raw_page = File.open(file).read
  fixed_str = Iconv.new('UTF-8//IGNORE', 'UTF-8').iconv(raw_page + ' ')[0..-2]
  Distillery::Document.new(fixed_str)
end

namespace :fixture do
  desc 'Open the fixture with data-score elements added showing an elements score'
  task :score, :filename do |t, args|
    doc = doc_for_fixture(args[:filename])
    doc.remove_irrelevant_elements!
    doc.remove_unlikely_elements!

    doc.score!
    doc.scores.each do |xpath, score|
      doc.at(xpath)['data-score'] = score.to_s
    end

    outfile = File.open("/tmp/scored.#{args[:filename]}", 'w')
    outfile << doc.to_s
    sh "open #{outfile.path}"
  end
  
  desc 'Distill a fixture and open it'
  task :distill, :filename do |t, args|
    outfile = File.open("/tmp/distilled.#{args[:filename]}", 'w')
    outfile << doc_for_fixture(args[:filename]).distill!
    sh "open #{outfile.path}"
  end
end

task :default => :spec