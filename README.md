# Distillery

Distillery extracts the "content" portion out of an HTML document.  It applies heuristics based on element type, location, class/id name and other attributes to try and find the content part of the HTML document and return it.

The logic for Distillery was heavily influenced by [Readability](https://www.readability.com/), who was nice enough to make [their logic](http://code.google.com/p/arc90labs-readability/source/browse/trunk/js/readability.js) open source.  Readability and Distillery share nearly the same logic for locating the content HTML element on the page, however Distillery does *not* aim to be a direct port of that logic (see [iterationlabs/ruby-readability](https://github.com/iterationlabs/ruby-readability) for that).

## Differences from Readability

Readability and Distillery differ in how they clean and return the found page content.  Readability is focused on stripping the page content down to just paragraphs of text for distraction-free reading, and thus aggressively cleans and transforms the content element HTML. Mostly, this is the conversion of some `<div>` elements and newlines to `<p>` elements.  Distillery does no transformation of the content element, and instead returns the content as originally seen in the HTML document.

## Installation

    gem install distillery

## Usage

Usage is quite simple:

    Distillery.distill(html_doc_as_a_string)
    > "distilled content"

If you would like a more OO oriented syntax, Distillery offers a `Distillery::Document` API.  Like the `distill` method above, its constructor takes a string that is the content of the HTML page you would like to distill:

    doc = Distillery::Document.new(string_of_html)

Then you simply call `#distill!` on the document object to distill it and return the distilled content.

    doc.distill!
    > "distilled content"
    
### Cleaning of the content

Both the `Distillery::Document#distill!` and `Distillery.distill` methods by default will clean the HTML of the content to remove elements from it which are unlikely to be the actual content.  Usually, this is things like social media share buttons, widgets, advertisements, etc.  If do not want to clean the content, simply pass `:clean => false` to either method:

    doc.distill!(:clean => false)
    > "raw distilled content"

In its cleaning, Distillery will also remove all `<img>` tags from the content element.  If you would like to preserve `<img>` tags, pass the `:images => true` option to the `Distillery::Document#distill!` and `Distillery.distill` methods.  Please note that this will preserve any elements that wrap `<img>` tags that would have been removed under normal circumstances during cleaning.

    doc.distill!(:images => true)
    > "raw distilled content with <img src=\"info.png\">"

## From the command line

Distillery also ships with an executable that allows you to distill documents at the command line:

    Usage: distill [options] http://www.example.com/
        -d, --dirty        Do not clean content HTML
        -v, --version      Print the version
        -h, --help         Print this help message