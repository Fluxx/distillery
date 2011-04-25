# Distillery

**This gem is a work in progress.  Not ready for production usage yet.**

Distillery extracts the "content" portion out of an HTML document.  It applies heuristics based on element type, location, class/id name and other attributes to try and find the content part of the HTML document and return it.

The logic for Distillery was heavily influenced by [Readability](https://www.readability.com/), who was nice enough to make [their logic](http://code.google.com/p/arc90labs-readability/source/browse/trunk/js/readability.js) open source.  Distillery does *not* aim to be a direct port of that logic.  See [iterationlabs/ruby-readability](https://github.com/iterationlabs/ruby-readability) for something closer to that.

## Usage

First, create a new `Distillery::Document` object, by passing in an a string that is the content of the HTML page you would like to distill

    doc = Distillery::Document.new(string_of_html)

Then you simply call `#distill!` on the document object to distill it and return the distilled content.

    doc.distill!
    > "distilled content"
    
The `#distill!` method by default will clean the HTML of the content to remove elements from it which are unlikely to be the actual content.  Usually, this is things like social media share buttons, widgets, advertisements, etc.  If you would like to not clean the content, simply pass `:dirty => true` to the `#distill!` method:

    doc.distill!(:dirty => true)
    > "raw distilled content"
    
## Advanced Usage

Under the covers, #distill! is removing unlikely elements, converting paragraph-like elements to actual `<p>`, scoring document elements based on some heuristics and cleaning the output of the content.  Soon you will be able to tweak how these heuristics are applied.