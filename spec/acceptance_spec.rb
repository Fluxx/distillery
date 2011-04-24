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

distillation_of 'clams_and_linguini.html' do
  should =~ /<h2>Linguini with Clam Sauce Recipe<\/h2>/
  should =~ /2 pounds small clams in the shell/
  should =~ /completely evaporated./

  should_not =~ /Licorice sounds interesting./              # Comment
  should_not =~ /Bookmark this page using the following/    # Footer
  should_not =~ /Google Search/                             # Header
end

distillation_of 'beef_jerkey.html' do
  should =~ /always had a weakness/
  should =~ /2 pounds trimmed beef top round/
  should =~ /Om nom nom nom/
  
  should_not =~ /Leave a Reply/                             # Footer
  should_not =~ /EMAIL SUBSCRIPTION/                        # Sidebar
  should_not =~ /allthingssimpleblog.com\/feed\//           # Header
end

distillation_of 'vanilla_pound_cake.html' do
  should =~ /Tahitian bean for its floral notes/
  should =~ /beat until light and fluffy/
  should =~ /cake comes out clean/
  
  should_not =~ /Pound cake is a classi/                    # Comments
  should_not =~ /Simple template. Powered by/               # Footer
  should_not =~ /Conversions and Measurement Tips/          # Header
end