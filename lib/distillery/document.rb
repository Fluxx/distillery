require "delegate"
require "nokogiri"

module Distillery

  class Document < SimpleDelegator

    UNLIKELY_TAGS = %w[head script link meta]
    UNLIKELY_IDENTIFIERS = /combx|comment|disqus|foot|header|menu|meta|nav|rss|shoutbox|sidebar|sponsor/i
    BLOCK_ELEMENTS = %w[a blockquote dl div img ol p pre table ul]
    POSITIVE_IDENTIFIERS = /article|body|content|entry|hentry|page|pagination|post|text/i
    NEGATIVE_IDENTIFIERS = /combx|comment|contact|foot|footer|footnote|link|media|meta|promo|related|scroll|shoutbox|sponsor|tags|widget/i
    UNRELATED_ELEMENTS = %w[iframe form object]
    POSSIBLE_UNRELATED_ELEMENTS = %w[table ul div]

    attr_reader :doc, :scores

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

    # Corrects improper use of HTML tags by coerceing elements that are likely paragraphs
    # to <p> tags
    #
    # TODO: Convert text nodes to <p> as well
    def coerce_elements_to_paragraphs!
      search('div').each do |div|
        div.name = "p" if has_no_block_children?(div) || has_only_empty_div_children?(div)
      end
    end

    # Scores the document elements based on an algorithm to find elements which hold page
    # content.
    #
    # Assign each paragraph a score
    # - Point per comma
    # - Point per set of 100 characters
    # - Points for low link-density
    # Parent gets sum of score of children, grandparent 1/2 the score of their children
    def score!
      search('p').each do |paragraph|
        points = 1
        points += paragraph.text.split(',').length
        points += [paragraph.text.length / 100, 3].min

        scores[paragraph.path] = points
        parent = paragraph.parent
        scores[parent.path] += points
        scores[parent.parent.path] += points.to_f/2
      end

      augment_scores_by_link_weight!
    end

    # Distills the document down to just its content
    def distill!(options = {})
      prep_for_distillation!
      score!
      clean_top_scoring_element! unless !!options.delete(:dirty)

      top_scoring_element.inner_html
    end

    # Attempts to clean the top scoring node from non-page content items, such as
    # advertisements, widgets, etc
    def clean_top_scoring_element!
      top_scoring_element.search("*").each do |node|
        node.remove if node.text.gsub(/\s/, '').empty?
      end

      top_scoring_element.search("*").each do |node|
        if UNRELATED_ELEMENTS.include?(node.name) || 
          (node.text.count(',') < 2 && unlikely_to_be_content?(node))
          node.remove
        end
      end
    end

    def prep_for_distillation!
      remove_irrelevant_elements!
      remove_unlikely_elements!
      coerce_elements_to_paragraphs!
      # TODO: Convert newline breaks to paragraphs
    end

    private

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

    def top_scoring_element
      sorted = scores.sort_by { |xpath, score| score }.reverse
      top_xpath, top_score = sorted.first.first
      at(top_xpath)
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