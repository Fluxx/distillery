require 'spec_helper'

module Distillery
  describe Document do

    let(:document) { File.open('./spec/fixtures/pina_collada_cupcakes.html').read }
    let!(:noko_doc) { ::Nokogiri::HTML(document) }
    subject { Document.new(document) }

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

  end
end