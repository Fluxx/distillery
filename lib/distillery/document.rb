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
        scores[parent.path] = scores[parent.path] + points

        grandparent = parent.parent
        scores[grandparent.path] = scores[grandparent.path] + points.to_f/2
      end

      augment_scores_by_link_weight!
    end

    # Distills the document down to just its content
    def distill!
      prep_for_distillation!
      score!
      clean_top_scoring_element!

      top_scoring_element.inner_html
    end

    # Attempts to clean the top scoring node from non-page content items, such as
    # advertisements, widgets, etc
    def clean_top_scoring_element!
      top_scoring_element.search("*").each do |node|
        if UNRELATED_ELEMENTS.include?(node.name)
          node.remove
        elsif POSSIBLE_UNRELATED_ELEMENTS.include?(node.name) && identifier_weight(node) < 0
          node.remove
        elsif unlikely_to_be_content?(node)
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
        link_length = at(xpath).search('a').reduce(0) { |total, e| total + e.text.length }
        total_length = [at(xpath).text.length, 1].max # Protect against dividing by 0
        scores[xpath] = scores[xpath] * (1 - link_length.to_f / total_length.to_f)
      end
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
      0.tap do |weight|
        {POSITIVE_IDENTIFIERS => 25, NEGATIVE_IDENTIFIERS => -25}.each do |regex, score|
          weight += score if elem['class'] =~ regex
          weight += score if elem['id'] =~ regex
        end
      end
    end

    def unlikely_to_be_content?(elem)
      false
    end

  end
end