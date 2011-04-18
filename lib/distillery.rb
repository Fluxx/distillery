require "distillery/document"

module Distillery

  UNLIKELY_TAGS = %w[head script link meta]
  UNLIKELY_CLASSES = /combx|comment|disqus|foot|header|menu|meta|nav|rss|shoutbox|sidebar|sponsor/i
  BLOCK_ELEMENTS = %w[a blockquote dl div img ol p pre table ul]

  def self.distill(document)
    # Parse the page with Nokogiri
    doc = Nokogiri::HTML(document)

    # Remove head, script, link tags, etc
    doc.search(*UNLIKELY_TAGS).each(&:remove)

    # Remove all nodes that have unlikely class names
    doc.search('*').each do |element|
      element.remove if element['class'] =~ UNLIKELY_CLASSES
    end

    # TODO: Convert newline breaks to paragraphs

    # Convert all divs with no bock-level element children to paragraphs.  Some people
    # wrap their paragraphs in divs, not p
    doc.search('div').each do |div|
      if (div.children.any? && div.children.none? { |c| BLOCK_ELEMENTS.include?(c.name) }) || (div.search('div').any? && div.search('div').all? { |sd| sd.text == "" })
        div.name = "p"
      end
    end

    scores = Hash.new(0)

    # Assign each paragraph a score
    # - Point per comma
    # - Point per set of 100 characters
    # - Points for low link-density
    # Parent gets sum of score of children, grandparent 1/2 the score of their children
    doc.search('p').each do |paragraph|
      points = 1
      points += paragraph.text.count(',')
      points += paragraph.text.length / 100
      points -= paragraph.children.css('a').count

      scores[paragraph.path] = points

      parent = paragraph.parent
      grandparent = parent.parent

      scores[parent.path] = scores[parent.path] + points
      scores[grandparent.path] = scores[grandparent.path] + points/2
    end

    scores = scores.sort_by { |xpath, score| score }.reverse
    # Sort the scores and look at our top candidate
    top_xpath, top_score = scores.first.first
    doc.search(top_xpath).inner_html
  end

end
