require 'spec_helper'

module Distillery
  describe Document do

    let(:document) { File.open('./spec/fixtures/pina_collada_cupcakes.html').read }
    let!(:noko_doc) { ::Nokogiri::HTML(document) }
    subject { Document.new(document) }

    def document_of(html)
      Document.new("<html><body>#{html}</body></html>")
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
          doc = Document.new("<html><body><div class='#{klass}'>foo</div></body></html>")
          doc.remove_unlikely_elements!
          doc.inner_html.should == "<html><body></body></html>"
        end
        it "removes any elements id'd ##{klass}, as it is unlikely to be page content" do
          doc = Document.new("<html><body><div id='#{klass}'>foo</div></body></html>")
          doc.remove_unlikely_elements!
          doc.inner_html.should == "<html><body></body></html>"
        end

      end

    end

    describe 'coerce_elements_to_paragraphs!' do

      it 'converts divs who have no children to paragraphs' do
        doc = Document.new("<html><body><div>foo</div></body></html>")
        doc.coerce_elements_to_paragraphs!
        doc.inner_html.should == "<html><body><p>foo</p></body></html>"
      end

      it 'converts divs who have children that are not block-level elements to paragraphs' do
        doc = Document.new("<html><body><div><span>foo</span></div></body></html>")
        doc.coerce_elements_to_paragraphs!
        doc.inner_html.should == "<html><body><p><span>foo</span></p></body></html>"
      end

      it 'converts divs whose have empty child divs to paragrahs' do
        doc = Document.new("<html><body><div><pre>foo</pre><div></div></div></body></html>")
        doc.coerce_elements_to_paragraphs!
        doc.inner_html.gsub("\n", "").should == "<html><body><p><pre>foo</pre><p></p></p></body></html>"
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
        doc = document_of("<p>foo</p><div>bar</div>")
        doc.score!
        doc.scores.should_not have_key('/html/body/div')
        doc.scores.should have_key('/html/body/p')
      end

      it 'gives one point per comma in the text of an element' do
        doc = document_of("<p>foo,bar,baz</p>")
        doc.score!
        doc.scores['/html/body/p'].should == 4
      end

      it 'gives one point per chunk of 100 characters, max of 3' do
        doc = document_of("<p>#{'f'*201}</p>")
        doc.score!
        doc.scores['/html/body/p'].should == 4

        doc = document_of("<p>#{'f'*1000}</p>")
        doc.score!
        doc.scores['/html/body/p'].should == 5
      end

      it 'adds its own points to its parent' do
        doc = document_of("<p><div><p>foo</p></div></p>")
        doc.score!
        doc.scores['/html/body/div/p'].should == 2
        doc.scores['/html/body/div'].should == 2
      end

      it 'adds 1/2 its points to its grandparent' do
        doc = document_of("<p><div><div><p>foo</p></div></div></p>")
        doc.score!
        doc.scores['/html/body/div/div/p'].should == 2
        doc.scores['/html/body/div/div'].should == 2
        doc.scores['/html/body/div'].should == 1
      end

      it 'scales the final score by the inverse link density' do
        doc = document_of("<p>foobar<a>baz</a></p>")
        doc.score!
        doc.scores['/html/body/p'].should == 1.3333333333333335
      end

    end

    describe 'clean_top_scoring_element!' do
      def scored_document_of(markup)
        doc = document_of(markup)
        doc.prep_for_distillation!
        doc.score!
        doc
      end

      it 'removes all empty elements' do
        doc = scored_document_of("<p>foo <div></div></p>")
        doc.clean_top_scoring_element!
        doc.search('div').should be_empty
      end

      %w[iframe form object].each do |tag|
        it "removes any #{tag} elements" do
          doc = scored_document_of("<p>foo <div><#{tag}></#{tag}></div></p>")
          doc.clean_top_scoring_element!
          doc.search(tag).should be_empty
        end
      end

      it 'removes elements that have negative scores' do
        doc = scored_document_of("<p>foo <div class='widget'>bar</div>")
        doc.clean_top_scoring_element!
        doc.search('div').should be_empty
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

    end

  end
end