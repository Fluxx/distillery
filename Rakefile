require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--profile]
  t.pattern = 'spec/**/*_spec.rb'
end

require "distillery"

def doc_for_fixture(fixture)
  file = File.join(File.dirname(__FILE__), 'spec', 'fixtures', fixture)
  Distillery::Document.new(File.open(file).read)
end

namespace :fixture do
  task :score, :filename do |t, args|
    doc = doc_for_fixture(args[:filename])

    doc.prep_for_distillation
    doc.scores.each do |xpath, score|
      doc.at(xpath)['data-score'] = score.to_s
    end

    outfile = File.open("/tmp/scored.#{args[:filename]}", 'w')
    outfile << doc.to_s
    sh "open #{outfile.path}"
  end
  
  task :distill, :filename do |t, args|
    outfile = File.open("/tmp/distilled.#{args[:filename]}", 'w')
    outfile << doc_for_fixture(args[:filename]).distill
    sh "open #{outfile.path}"
  end
end

task :default => :spec