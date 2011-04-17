require File.dirname(__FILE__) + '/test_helper.rb'

class TestExtractContent < Test::Unit::TestCase

  def setup
    @extractor = ExtractContent::Extractor.new
  end
  
  def test_extractor
    body, title = @extractor.analyse(TEST_HTML)
    assert_equal body, TEST_TEXT
    assert_equal title, "extractcontent"
  end


  TEST_HTML = <<HTML
<html>
	<head>
		<meta http-equiv="Content-type" content="text/html; charset=utf-8">
		<title>extractcontent</title>
		
	</head>
	<body id="body">
		<p>This page has not yet been created for RubyGem <code>extractcontent</code></p>
		<p>To the developer: To generate it, update website/index.txt and run the rake task <code>website</code> to generate this <code>index.html</code> file.</p>
	</body>
</html>
HTML
  TEST_TEXT = "\nThis page has not yet been created for RubyGem extractcontent\nTo the developer: To generate it, update website/index.txt and run the rake task website to generate this index.html file.\n"

end
