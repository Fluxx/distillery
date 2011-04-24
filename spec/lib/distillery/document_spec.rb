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

    describe 'remove_irrelevant_elements' do

      %w[script link meta].each do |tag|
        it "should strip out ##{tag} tags" do
          subject.search(tag).should_not be_empty
          subject.remove_irrelevant_elements
          subject.search(tag).should be_empty
        end
      end

    end

    describe 'remove_unlikely_elements' do
      %w[combx comment disqus foot header menu meta nav rss shoutbox sidebar sponsor].each do |klass|
        it "removes any elements classed .#{klass}, as it is unlikely to be page content" do
          doc = Document.new("<html><body><div class='#{klass}'>foo</div></body></html>")
          doc.remove_unlikely_elements
          doc.inner_html.should == "<html><body></body></html>"
        end
        it "removes any elements id'd ##{klass}, as it is unlikely to be page content" do
          doc = Document.new("<html><body><div id='#{klass}'>foo</div></body></html>")
          doc.remove_unlikely_elements
          doc.inner_html.should == "<html><body></body></html>"
        end

      end

    end

    describe 'coerce_elements_to_paragraphs' do

      it 'converts divs who have no children to paragraphs' do
        doc = Document.new("<html><body><div>foo</div></body></html>")
        doc.coerce_elements_to_paragraphs
        doc.inner_html.should == "<html><body><p>foo</p></body></html>"
      end

      it 'converts divs who have children that are not block-level elements to paragraphs' do
        doc = Document.new("<html><body><div><span>foo</span></div></body></html>")
        doc.coerce_elements_to_paragraphs
        doc.inner_html.should == "<html><body><p><span>foo</span></p></body></html>"
      end

      it 'converts divs whose have empty child divs to paragrahs' do
        doc = Document.new("<html><body><div><pre>foo</pre><div></div></div></body></html>")
        doc.coerce_elements_to_paragraphs
        doc.inner_html.gsub("\n", "").should == "<html><body><p><pre>foo</pre><div></div></p></body></html>"
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

      it 'gives one point to elements by default' do
        doc = document_of("<p>foo</p>")
        doc.score!
        doc.scores['/html/body/p'].should == 1
      end

      it 'gives one point per comma in the text of an element' do
        doc = document_of("<p>foo,bar,baz</p>")
        doc.score!
        doc.scores['/html/body/p'].should == 3
      end

      it 'gives one point per chunk of 100 characters' do
        doc = document_of("<p>#{'f'*201}</p>")
        doc.score!
        doc.scores['/html/body/p'].should == 3
      end

      it 'subtracts a point for any links in a element' do
        doc = document_of("<p><a>foo</a></p>")
        doc.score!
        doc.scores['/html/body/p'].should == 0
      end

      it 'adds its own points to its parent' do
        doc = document_of("<p><div><p>foo</p></div></p>")
        doc.score!
        doc.scores['/html/body/div/p'].should == 1
        doc.scores['/html/body/div'].should == 1
      end

      it 'adds 1/2 its points to its grandparent' do
        doc = document_of("<p><div><div><p>foo</p></div></div></p>")
        doc.score!
        doc.scores['/html/body/div/div/p'].should == 1
        doc.scores['/html/body/div/div'].should == 1
        doc.scores['/html/body/div'].should == 0.5
      end

    end

    describe '#distill' do
      it 'returns the page content' do
        subject.distill.should =~ /great for lazy bakers/
      end

      it 'returns markup without the header' do
        subject.distill.should_not =~ /skinnytasteheader_1000_3/
      end

      it 'returns markup withouth the footer' do
        subject.distill.should_not =~ /Design by Call Me Kristin/
      end

      it 'returns markup without navigation' do
        subject.distill.should_not =~ /STNavbar1/
      end

      it 'returns markup without comments' do
        subject.distill.should_not =~ /Cindy said.../
      end

      it 'keeps the encoding of the string was passed in to the constructor' do
        string = "<html><body><p>foo</p></body></html>"
        string.encode!('ISO-8859-1')
        Document.new(string).distill.encoding.name.should == 'ISO-8859-1'
      end

      it 'returns a document with no empty elements' do
        Nokogiri::HTML(subject.distill).search("*").each do |element|
          element.text.should_not be_empty
        end
      end

    end

  end
end