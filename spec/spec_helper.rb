require 'distillery'
require 'rspec'

Dir['./spec/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.color_enabled = true

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end