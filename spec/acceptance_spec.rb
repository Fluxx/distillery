require 'spec_helper'
require 'iconv'

def distillation_of(filename, options = {}, &block)

  describe "distillation of #{filename}" do

    let(:raw_fixture_data) do
      File.read(File.join(File.dirname(__FILE__), 'fixtures', filename))
    end

    let(:fixture) {
      Iconv.new('UTF-8//IGNORE', 'UTF-8').iconv(raw_fixture_data + ' ')[0..-2]
    }

    subject { Distillery::Document.new(fixture).distill!(options) }

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

  # Verify links are kept
  should =~ Regexp.new('http://www.foodandwine.com/recipes/sweet-and-spicy-jerky')
  should =~ Regexp.new('http://www.foodandwine.com/recipes/mexican-lime-jerky')
  should =~ Regexp.new('http://en.wordpress.com/tag/beef-jerky/')

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

distillation_of 'clouds_shining_moment.html' do
  should =~ /The Dueling Models of Cloud Computing/
  should =~ /These kinds of failures don't expose the weaknesses/
  should =~ /Dynamic DNS pointing to elastic load balancers/

  should_not =~ /Razi Sharir/                               # Comments
  should_not =~ /All trademarks and registered/             # Footer
  should_not =~ /Community Guidelines/                      # Header
end

distillation_of 'game_blog.html' do
  should =~ /Currently in my Plants vs Zombies clone/
  should =~ /50% they start to show sign/
  should =~ /can never get enough feedback./

  should_not =~ /Tutorials/                                 # Header
  should_not =~ /Java Project/                              # Sidebar
  should_not =~ /View all comments/                         # Footer
end

distillation_of 'js_this_keyword.html' do
  should =~ /keyword is ubiquitous yet misconceptions abound/
  should =~ /in ECMAScript parlance these are/
  should =~ /Annex C/

  should_not =~ /11 RESPONSES TO UNDERSTANDING/             # Footer
  should_not =~ /The JavaScript Comma Operator/             # Sidebar
  should_not =~ /Auto-generating JavaScript Unit Test/      # Header
end

distillation_of 'nyt_social_media.html' do
  should =~ /What happens if you bring together/
  should =~ /shows a 2D bar-graph-like timeline/
  should =~ /then to explore several links/

  should_not =~ /ADD A COMMENT/                             # Comments
  should_not =~ /ABOUT 1,000 POSTS AGO/                     # Sidebar
  should_not =~ /iPhone Tracker: How your/                  # Header

  # Verify links are kept
  should =~ Regexp.new('http://nytlabs.com/projects/cascade.html')
end

distillation_of 'ginger_cookies.html' do
  should =~ /Ginger cookies are chilled/
  should =~ /12 minutes/
  should =~ /Makes about 4 dozen crispy/

  should_not =~ /Sponsored Links/                             # Sidebar
  should_not =~ /User Reviews/                                # Comments
  should_not =~ /Free Southern Food Newsletter!/              # Header
end

distillation_of 'bourbon_balls.html' do
  should =~ /The Kentucky Derby will be run Saturday/
  should =~ /Just drop one of your bourbon balls into a cup of coffee/
  should =~ /You can also use the ganache as a cake frosting/

  should_not =~ /I just tried the recipe forCellar Doo/       # Comments
  should_not =~ /FIND A STATION/                              # Header
  should_not =~ /Car Talk/                                    # Footer
end

distillation_of 'bulgogi.html' do
  subject.slice(0..1700).should include('looking to create a menu')
  subject.scan(/American to not fuss about the origin/).should have(1).result
  should =~ /early-season barbecue/
  should =~ /Still, it is American to not fuss/
  should =~ /vegetarians/                                     # Related link
end

distillation_of 'tofu_bowl.html' do
  subject.should =~ /Whisk together/
  subject.should =~ /minced fresh ginger/
  subject.should_not =~ /Add a comment/                          # Comment
  subject.should_not =~ /this is the best comfort food/          # Comment
  subject.should_not =~ /Please send me my 2 FREE trial/         # Footer
end

distillation_of 'pumpkin_scones.html' do
  subject.should =~ /Starbucks Pumpkin Scones Recipe/
  subject.should =~ /These pumpkin scones are so moist and flavorful/
  subject.should =~ /Makes 6 pumpkin scones/
  subject.should_not =~ /NEWEST RECIPES/
  subject.should_not =~ /Family Life/
end

distillation_of 'bilays.html' do
  subject.should =~ %r|http://smittenkitchen.com/2008/03/swiss-easter-rice-tart/|
  subject.should =~ /The Bread Bible/
  subject.should =~ /Arugula Ravioli/
  subject.should_not =~ /homemade chocolate wafers + icebox cupcakes/
  subject.should_not =~ /Would I be able to simply knead/

  # Verify links are kept
  subject.should =~ Regexp.new('http://smittenkitchen.com/2007/09/bronx-worthy-bagels/')
  subject.should =~ Regexp.new('http://smittenkitchen.com/2008/03/swiss-easter-rice-tart/')
  subject.should =~ Regexp.new('http://astore.amazon.com/smitten-20/detail/0393057941')
  subject.should =~ Regexp.new('http://www.kossarsbialys.com/')
end

distillation_of 'maple_cookies.html', images: true do
  subject.should =~ %r|http://farm8.staticflickr.com/7010/6466770921_6cdc30e27e.jpg|
  subject.should =~ %r|http://farm8.staticflickr.com/7175/6466771851_a9a82d1ddc.jpg|
  subject.should =~ %r|http://farm8.staticflickr.com/7014/6466788173_1898db6772.jpg|
  subject.should =~ %r|http://farm8.staticflickr.com/7006/6466777445_c9661aae40.jpg|
end

distillation_of 'swiss_chard_pie.html', images: true do
  subject.should =~ /You may be familiar with Spanakopita/
  subject.should =~ /Bring a large pot of generously salted/
  subject.should =~ /for 10 to 20 minutes./
end

distillation_of 'mothers_brisket.html' do
  subject.should =~ /Prep time: /
  subject.should =~ /onions until deep golden/
  subject.should =~ /3 tablespoons.+vegetable oil/
  subject.should =~ /Preheat the oven to 375/
  subject.should =~ /oven for about 30 minutes/
end

distillation_of 'oyako.html' do
  subject.should =~ /Ingredients:/
  subject.should =~ /4 servings/
  subject.should =~ /Goes well with a clear soup/
end