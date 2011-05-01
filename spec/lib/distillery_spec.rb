require 'spec_helper'

describe Distillery do

  describe '.distill' do

    let(:document) { File.open('./spec/fixtures/pina_collada_cupcakes.html').read }
    let(:mockdoc) { mock(:doc, :distill => 'test') }

    it 'takes a string and returns the distilled markup' do
      Distillery.distill(document).should be_a(String)
    end

    it 'defers to Distillery::Document' do
      Distillery::Document.should_receive(:new).once.with(document).and_return(mockdoc)
      mockdoc.should_receive(:distill!).once
      Distillery.distill(document)
    end

    it 'passes the same options through to the distill! method' do
      Distillery::Document.stub!(:new).and_return(mockdoc)
      mockdoc.should_receive(:distill!).once.with(hash_including(:clean => false))
      Distillery.distill(document, :clean => false)
    end
  end

end