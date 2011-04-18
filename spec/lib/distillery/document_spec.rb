require 'spec_helper'

module Distillery
  describe Document do

    describe ".new" do

      it 'raises an exception without an argument' do
        expect { Document.new }.to raise_exception(ArgumentError)
      end

    end

    describe 'nokogiri delegation' do
      let(:document) { '<head><title>foo</title></head><body><b>Fun!</b></body>'}
      let!(:noko_doc) { ::Nokogiri::HTML(document) }
      subject { Document.new(document) }

      before(:each) do
        ::Nokogiri.stub(:HTML).and_return(noko_doc)
        noko_doc.stub!(:to_xml).and_return('xml-doc')
      end

      it "delegates method_calls to the internal doc" do
        noko_doc.should_receive(:to_xml).once
        subject.to_xml.should == 'xml-doc'
      end

    end

  end
end