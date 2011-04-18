require "delegate"

module Distillery
  
  class Document < SimpleDelegator
    
    attr_reader :doc
    
    def initialize(page_string)
      super(::Nokogiri::HTML(page_string))
    end
    
  end
end