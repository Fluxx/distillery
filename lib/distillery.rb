require "distillery/document"
require "distillery/version"

module Distillery
  ROOT = File.dirname(__FILE__)

  # Distills the HTMl document string to just the conent portion.
  #
  # @param [String] str The HTML document to distill as a string.
  # @param [Hash] options Distillation options
  # @option options [Symbol] :dirty Do not clean the content element HTML
  def self.distill(str, options = {})
    Document.new(str).distill!(options)
  end
end
