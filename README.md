# Distillery

**This gem is a work in progress.  Not ready for production usage yet.**

Distillery extracts the "content" portion out of an HTML document.  It applies heuristics based on element type, location, class/id name and other attributes to try and find the content part of the HTML document and return it.

The logic for Distillery was heavily influenced by [Readability](https://www.readability.com/), who was nice enough to make [their logic](http://code.google.com/p/arc90labs-readability/source/browse/trunk/js/readability.js) open source.  Distillery does *not* aim to be a direct port of that logic.  See [iterationlabs/ruby-readability](https://github.com/iterationlabs/ruby-readability) for something closer to that.

## Usage

Usage is quite simple:

    doc = Distillery::Document.new(string_of_html)
    doc.distill
    > "distilled HTML content"