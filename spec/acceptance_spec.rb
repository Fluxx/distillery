require 'spec_helper'

def distillation_of(filename, &block)

  describe "distillation of #{filename}" do

    let(:fixture) do
      File.read(File.join(File.dirname(__FILE__), 'fixtures', filename))
    end

    subject { Distillery::Document.new(fixture).distill }

    it 'should include the right elements' do
      instance_eval(&block)
    end
  end
end

distillation_of 'agave_cookies.html' do
  should =~ /AGAVE &amp; HONEY OATMEAL M&amp;M COOKIES/
  should =~ /2 Tbsp lightly beaten egg/
  should =~ /Recipe Source:/

  should_not =~ /I am a HUGE fan of agave and cook/         # Post comment
  should_not =~ /mnuEntertaining/                           # ID of element in header
  should_not =~ /Get Email Updates/                         # Sidebar
  should_not =~ /id="footer"/                               # Footer
end