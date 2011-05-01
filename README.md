# Distillery

Distillery extracts the "content" portion out of an HTML document.  It applies heuristics based on element type, location, class/id name and other attributes to try and find the content part of the HTML document and return it.

**Note: Distillery has only been tested with Ruby 1.9**

The logic for Distillery was heavily influenced by [Readability](https://www.readability.com/), who was nice enough to make [their logic](http://code.google.com/p/arc90labs-readability/source/browse/trunk/js/readability.js) open source.  Distillery does *not* aim to be a direct port of that logic.  See [iterationlabs/ruby-readability](https://github.com/iterationlabs/ruby-readability) for something closer to that.

Readability and Distillery share nearly the same logic for locating the content HTML element on the page.  Readability, however, also aggressively cleans and transforms the content element HTML to be used for display in a reading environment.  Distillery aims to clean slightly less aggressively, and allow the user of the gem to choose how (and if) they would like to clean content element HTML.

## Usage

Usage is quite simple:

    Distillery.distill(html_doc_as_a_string)
    > "distilled content"

If you would like a more OO oriented syntax, Distillery offers a `Distillery::Document` API.  Like the `distill` method above, its constructor takes a string that is the content of the HTML page you would like to distill:

    doc = Distillery::Document.new(string_of_html)

Then you simply call `#distill!` on the document object to distill it and return the distilled content.

    doc.distill!
    > "distilled content"

Both the `Distill::Document#distill!` and `Distillery.distill` methods by default will clean the HTML of the content to remove elements from it which are unlikely to be the actual content.  Usually, this is things like social media share buttons, widgets, advertisements, etc.  If you would like to not clean the content, simply pass `:dirty => true` to either method:

    doc.distill!(:dirty => true)
    > "raw distilled content"