require "delegate"
require "nokogiri"

module Distillery

  class Document < SimpleDelegator

    UNLIKELY_TAGS = %w[head script link meta]
    UNLIKELY_CLASSES = /combx|comment|disqus|foot|header|menu|meta|nav|rss|shoutbox|sidebar|sponsor/i
    BLOCK_ELEMENTS = %w[a blockquote dl div img ol p pre table ul]

    attr_reader :doc

    def initialize(page_string)
      super(::Nokogiri::HTML(page_string))
    end

    # Removes irrelevent elements from the document.  This is usually things like <script>,
    # <link> and other page elements we don't care about
    def remove_irrelevant_elements(tags = UNLIKELY_TAGS)
      search(*tags).each(&:remove)
    end

    # Removes unlikely elements from the document.  These are elements who have classes
    # that seem to indicate they are comments, headers, footers, nav, etc
    def remove_unlikely_elements
      search('*').each do |element|
        element.remove if element['class'] =~ UNLIKELY_CLASSES
      end
    end

    # Corrects improper use of HTML tags by coerceing elements that are likely paragraphs
    # to <p> tags
    def coerce_elements_to_paragraphs
      search('div').each do |div|
        div.name = "p" if has_no_block_children?(div) || has_only_empty_div_children?(div)
      end
    end
    
    private
    
    def has_no_block_children?(elem)
      elem.children.any? && elem.children.none? { |c| BLOCK_ELEMENTS.include?(c.name) }
    end
    
    def has_only_empty_div_children?(elem)
      elem.search('div').any? && elem.search('div').all? { |subdiv| subdiv.text == "" }
    end
    
  end
end