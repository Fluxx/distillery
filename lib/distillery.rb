require "distillery/document"

module Distillery
  ROOT = File.dirname(__FILE__)

  def self.distill(str, options = {})
    Document.new(str).distill!(options)
  end
end
