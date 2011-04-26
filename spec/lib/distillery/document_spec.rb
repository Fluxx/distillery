require 'spec_helper'

module Distillery
  describe Document do

    let(:document) { File.open('./spec/fixtures/pina_collada_cupcakes.html').read }
    let!(:noko_doc) { ::Nokogiri::HTML(document) }
    subject { Document.new(document) }

    def document_of(html, *postprocessing)
      Document.new(html_of(html)).tap do |doc|
        postprocessing.each do |method|
          doc.send(method)
        end
      end
    end

    def html_of(body)
      "<html><body>#{body}</body></html>"
    end

    describe ".new" do

      it 'raises an exception without an argument' do
        expect { Document.new }.to raise_exception(ArgumentError)
      end

    end

    describe 'nokogiri delegation' do

      before(:each) do
        ::Nokogiri.stub(:HTML).and_return(noko_doc)
        noko_doc.stub!(:to_xml).and_return('xml-doc')
      end

      it "delegates method_calls to the internal doc" do
        noko_doc.should_receive(:to_xml).once
        subject.to_xml.should == 'xml-doc'
      end

    end

    describe 'remove_irrelevant_elements!' do

      %w[script link meta].each do |tag|
        it "should strip out ##{tag} tags" do
          subject.search(tag).should_not be_empty
          subject.remove_irrelevant_elements!
          subject.search(tag).should be_empty
        end
      end

      it 'does not remove the body even if it has a bad class or id' do
        doc = Document.new("<html><body class='sidebar'>foo</body></html>")
        doc.remove_unlikely_elements!
        doc.search('body').should_not be_empty
      end

    end

    describe 'remove_unlikely_elements!' do
      %w[combx comment disqus foot header menu meta nav rss shoutbox sidebar sponsor].each do |klass|
        it "removes any elements classed .#{klass}, as it is unlikely to be page content" do
          doc = document_of("<div class='#{klass}'>foo</div>", :remove_unlikely_elements!)
          doc.inner_html.should == html_of("")
        end
        it "removes any elements id'd ##{klass}, as it is unlikely to be page content" do
          doc = document_of("<div id='#{klass}'>foo</div>", :remove_unlikely_elements!)
          doc.inner_html.should == html_of("")
        end

      end

    end

    describe 'coerce_elements_to_paragraphs!' do

      it 'converts divs who have no children to paragraphs' do
        doc = document_of("<div>foo</div>", :coerce_elements_to_paragraphs!)
        doc.inner_html.should == html_of("<p>foo</p>")
      end

      it 'converts divs who have children that are not block-level elements to paragraphs' do
        doc = document_of("<div><span>foo</span></div>", :coerce_elements_to_paragraphs!)
        doc.inner_html.should == html_of("<p><span>foo</span></p>")
      end

      it 'converts divs whose have empty child divs to paragrahs' do
        doc = document_of("<div><pre>foo</pre><div></div></div>", :coerce_elements_to_paragraphs!)
        doc.inner_html.gsub("\n", "").should == html_of("<p><pre>foo</pre><p></p></p>")
      end

    end

    describe '#score!' do

      it 'popualtes the score ivar with data' do
        subject.scores.should be_a(Hash)
        subject.scores.should be_empty
        subject.score!
        subject.scores.should_not be_empty
      end

      it 'only calculates scores for paragraphs' do
        doc = document_of("<p>foo</p><div>bar</div>", :score!)
        doc.scores.should_not have_key('/html/body/div')
        doc.scores.should have_key('/html/body/p')
      end

      it 'gives one point per comma in the text of an element' do
        doc = document_of("<p>foo,bar,baz</p>", :score!)
        doc.scores['/html/body/p'].should == 4
      end

      it 'gives one point per chunk of 100 characters, max of 3' do
        doc = document_of("<p>#{'f'*201}</p>", :score!)
        doc.scores['/html/body/p'].should == 4

        doc = document_of("<p>#{'f'*1000}</p>", :score!)
        doc.scores['/html/body/p'].should == 5
      end

      it 'adds its own points to its parent' do
        doc = document_of("<p><div><p>foo</p></div></p>", :score!)
        doc.scores['/html/body/div/p'].should == 2
        doc.scores['/html/body/div'].should == 2
      end

      it 'adds 1/2 its points to its grandparent' do
        doc = document_of("<p><div><div><p>foo</p></div></div></p>", :score!)
        doc.scores['/html/body/div/div/p'].should == 2
        doc.scores['/html/body/div/div'].should == 2
        doc.scores['/html/body/div'].should == 1
      end

      it 'scales the final score by the inverse link density' do
        doc = document_of("<p>foobar<a>baz</a></p>", :score!)
        doc.scores['/html/body/p'].should == 1.3333333333333335
      end

    end

    describe 'clean_top_scoring_element!' do
      def doc_with_top_scored_html_of(markup, *postprocessing)
        markup = '<div class="winner">' + ('<p>foo,</p>'*5) + markup + '</div>'
        document_of(markup, *[:prep_for_distillation!, :score!].push(*postprocessing))
      end

      it 'removes all empty elements' do
        doc = doc_with_top_scored_html_of("<div>foo <span></span</div>", :clean_top_scoring_element!)
        doc.search('span').should be_empty
      end

      %w[iframe form object].each do |tag|
        it "removes any #{tag} elements" do
          doc = doc_with_top_scored_html_of("foo <#{tag}></#{tag}>", :clean_top_scoring_element!)
          doc.search(tag).should be_empty
        end
      end

      it 'removes elements that have negative scores' do
        doc = doc_with_top_scored_html_of("<div class='widget'><div>bar</div></div>", :clean_top_scoring_element!)
        doc.search('.widget').should be_empty
      end

      it 'removes elements that have more images than p tags' do
        doc = doc_with_top_scored_html_of("<div class='remove'><img><img><img><p>bar</p><div>foo</div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty
      end

      it 'removes elements that have way more li elements and it is not a list' do
        doc = doc_with_top_scored_html_of("<div class='remove'><div>me<ul>#{'<li>a</li>'*200}</ul></div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty
      end

      it 'removes elements that have more inputs than 1/3 the amount of p tags' do
        doc = doc_with_top_scored_html_of("<div class='remove'><div><input><input><p>f</p><p>f</p><p>f</p></div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty

        doc = doc_with_top_scored_html_of("<div class='remove'><input><p>#{'f'*25}</p><p>f</p><p>f</p></div>", :clean_top_scoring_element!)
        doc.search('.remove').should_not be_empty
      end

      it 'removes elements that have < 25 characters and (no images or > 2 images' do
        doc = doc_with_top_scored_html_of("<div class='remove'><div>foo</div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty

        doc = doc_with_top_scored_html_of("<div class='remove'><div>foo <img><img><img></div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty
      end

      it 'removes elements that have a weight of < 25 and link density > 0.2' do
        doc = doc_with_top_scored_html_of("<div class='remove'><div>fffff<a>#{'b'*2}</a></div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty
      end

      it 'removes elements that have a weight of >= 25 and link density > 0.5' do
        doc = doc_with_top_scored_html_of("<div class='remove article'><div>#{'f'*100}<a>#{'b'*150}</a></div></div>", :clean_top_scoring_element!)
        doc.search('.remove').should be_empty
      end

      it 'should not clean elements not of table ul or div' do
        doc = doc_with_top_scored_html_of("<span class='remove'><strong>Source:</strong> Wikipedia</span>", :clean_top_scoring_element!)
        doc.search('.remove').should_not be_empty
      end

    end

    describe '#distill!' do
      it 'returns the page content' do
        subject.distill!.should =~ /great for lazy bakers/
      end

      it 'returns markup without the header' do
        subject.distill!.should_not =~ /skinnytasteheader_1000_3/
      end

      it 'returns markup withouth the footer' do
        subject.distill!.should_not =~ /Design by Call Me Kristin/
      end

      it 'returns markup without navigation' do
        subject.distill!.should_not =~ /STNavbar1/
      end

      it 'returns markup without comments' do
        subject.distill!.should_not =~ /Cindy said.../
      end

      it 'keeps the encoding of the string was passed in to the constructor' do
        string = "<html><body><p>foo</p></body></html>"
        string.encode!('ISO-8859-1')
        Document.new(string).distill!.encoding.name.should == 'ISO-8859-1'
      end

      it 'does not clean the page if :dirty => true is passed' do
        doc = Document.new(File.open('./spec/fixtures/baked_ziti.html').read)
        doc.distill!(:dirty => true).should =~ /Add to Recipe Box/

        doc = Document.new(File.open('./spec/fixtures/baked_ziti.html').read)
        doc.distill!.should_not =~ /Add to Recipe Box/
      end

    end

  end
end