require "delegate"
require "nokogiri"

module Distillery

  # Wraps a Nokogiri document for the HTML page to be disilled and holds all methods to
  # clean and distill the document down to just its content element.
  class Document < SimpleDelegator

    # HTML elements unlikely to contain the content element.
    UNLIKELY_TAGS = %w[head script link meta]

    # HTML ids and classes that are unlikely to contain the content element.
    UNLIKELY_IDENTIFIERS = /combx|comment|disqus|foot|header|menu|meta|nav|rss|shoutbox|sidebar|sponsor/i

    # "Block" elements who signal its parent is less-likely to be the content element.
    BLOCK_ELEMENTS = %w[a blockquote dl div img ol p pre table ul]

    # HTML ids and classes that are positive signals of the content element.
    POSITIVE_IDENTIFIERS = /article|body|content|entry|hentry|page|pagination|post|text/i

    # HTML ids and classes that are negative signals of the content element.
    NEGATIVE_IDENTIFIERS = /combx|comment|contact|foot|footer|footnote|link|media|meta|promo|related|scroll|shoutbox|sponsor|tags|widget/i

    # HTML elements that are unrelated to the content in the content element.
    UNRELATED_ELEMENTS = %w[iframe form object]

    # HTML elements that are possible unrelated to the content of the content HTML
    # element.
    POSSIBLE_UNRELATED_ELEMENTS = %w[table ul div]

    # The Nokogiri document
    attr_reader :doc

    # Hash of xpath => content score of elements in this document
    attr_reader :scores

    # Create a new Document
    #
    # @param [String] str The HTML document to distill as a string.
    def initialize(page_string)
      @scores = Hash.new(0)
      super(::Nokogiri::HTML(page_string))
    end

    # Removes irrelevent elements from the document.  This is usually things like <script>,
    # <link> and other page elements we don't care about
    def remove_irrelevant_elements!(tags = UNLIKELY_TAGS)
      search(*tags).each(&:remove)
    end

    # Removes unlikely elements from the document.  These are elements who have classes
    # that seem to indicate they are comments, headers, footers, nav, etc
    def remove_unlikely_elements!
      search('*').each do |element|
        idclass = "#{element['class']}#{element['id']}"
        element.remove if idclass =~ UNLIKELY_IDENTIFIERS && element.name != 'body'
      end
    end

    # Marks elements that are suitable for scoring with a special HTML attribute
    def mark_scorable_elements!
      search('div', 'p').each do |element|
        if element.name == 'p' || scorable_div?(element)
          element['data-distillery'] = 'scorable'
        end
      end
    end

    # Scores the document elements based on an algorithm to find elements which hold page
    # content.
    def score!
      mark_scorable_elements!

      scorable_elements.each do |element|
        points = 1
        points += element.text.split(',').length
        points += [element.text.length / 100, 3].min

        scores[element.path] = points
        scores[element.parent.path] += points
        scores[element.parent.parent.path] += points.to_f/2
      end

      augment_scores_by_link_weight!
    end

    # Distills the document down to just its content.
    #
    # @param [Hash] options Distillation options
    # @option options [Symbol] :dirty Do not clean the content element HTML
    def distill!(options = {})
      remove_irrelevant_elements!
      remove_unlikely_elements!

      score!

      clean_top_scoring_elements!(options) unless options.delete(:clean) == false
      top_scoring_elements.map(&:inner_html).join("\n")
    end

    # Attempts to clean the top scoring node from non-page content items, such as
    # advertisements, widgets, etc
    def clean_top_scoring_elements!(options = {})
      keep_images = !!options[:images]

      top_scoring_elements.each do |element|

        element.search("*").each do |node|
          next if (node.name == 'img' || node.children.css('img').any?) && keep_images
          node.remove if has_empty_text?(node)
        end

        element.search("*").each do |node|
          next if node.name == 'img' && keep_images
          if UNRELATED_ELEMENTS.include?(node.name) ||
            (node.text.count(',') < 2 && unlikely_to_be_content?(node))
            node.remove
          end
        end
      end
    end

    private

    def scorable_elements
      search('[data-distillery=scorable]')
    end

    def augment_scores_by_link_weight!
      scores.each do |xpath, points|
        scores[xpath] = scores[xpath] * ( 1 - link_density(at(xpath)) )
      end
    end

    def link_density(elem)
      link_length = elem.search('a').reduce(0) { |total, e| total + e.text.length }
      total_length = [elem.text.length, 1].max # Protect against dividing by 0
      link_length.to_f / total_length.to_f
    end

    def top_scoring_elements
      # -score puts largest scores first, then by xpath to favor outter elements on tie
      winner = scores.sort_by { |xpath, score| [-score, xpath] }.first
      top_xpath, top_score = winner || ['/html/body', 1]
      top_element = at(top_xpath)

      top_elements = [top_element]

      top_element.parent.children.each do |sibling|
        top_elements << sibling if related_sibling?(top_element, sibling)
      end

      top_elements.each do |element|
        element.search('[data-distillery]').each do |element|
          element.remove_attribute('data-distillery')
        end
      end

      top_elements
    end

    def related_sibling?(top_element, sibling)
      score = scores[sibling.path]
      top_score = scores[top_element.path]
      identical = identical_attrubutes?(top_element, sibling)

      (score > top_score*025 || (identical && score > top_score*0.05)) &&
      sibling.path != top_element.path
    end

    def identical_attrubutes?(a, b)
      a['id'] == b['id'] && a['class'] == b['class']
    end

    def scorable_div?(elem)
      elem.name == 'div' &&
        (has_no_block_children?(elem) || has_only_empty_div_children?(elem))
    end

    def has_no_block_children?(elem)
      elem.children.none? { |c| BLOCK_ELEMENTS.include?(c.name) }
    end

    def has_only_empty_div_children?(elem)
      elem.search('div').all? { |subdiv| subdiv.text == "" }
    end

    def identifier_weight(elem)
      {POSITIVE_IDENTIFIERS => 25, NEGATIVE_IDENTIFIERS => -25}.reduce(0) do |weight, pair|
        regex, score = pair
        (weight += score if "#{elem['class']}+#{elem['id']}" =~ regex) or weight
      end
    end

    def has_empty_text?(elem)
      elem.text.gsub(/\s/, '').empty? && elem.name != 'br'
    end

    def unlikely_to_be_content?(elem)
      return false unless POSSIBLE_UNRELATED_ELEMENTS.include?(elem.name)

      p = elem.search('p').length
      img = elem.search('img').length
      li = elem.search('li').length
      input = elem.search('input').length
      weight = identifier_weight(elem)
      link_density = link_density(elem)

      weight < 0 ||                                        # Terrible weight
      elem.text.empty? || elem.text.length < 15 ||         # Empty text or too short text
      img > p ||                                           # More images than paragraphs
      li > p && !(elem.name =~ /ul|ol/) ||                 # Has lots of list items
      input > p / 3 ||                                     # Has a high % of inputs
      elem.text.length < 25 && (img == 0 || img > 2) ||    # Short text + no/high img count
      weight < 25 && link_density > 0.2 ||                 # Weak content signal and moderate link density
      weight >= 25 && link_density > 0.5                   # Strong content signal and high link density
    end

  end
end