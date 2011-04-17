#!/usr/bin/ruby -Ku
$KCODE="u"

# Author:: Nakatani Shuyo
# Copyright:: (c)2007/2008 Cybozu Labs Inc. All rights reserved.
# License:: BSD

# = ExtractContent : Extract Content Module for html
# This module is to extract the text from web page ( html content ).
# Automatically extracts sub blocks of html which have much possibility that it is the text
# ( except for menu, comments, navigations, affiliate links and so on ).

# == PROCESSES
# - separating blocks from html, calculating score of blocks and ignoring low score blocks.
# - for score calculation, using block arrangement, text length, whether has affiliate links or characteristic keywords
# - clustering continuous, high score blocks and comparing amang clusters
# - if including "Google AdSense Section Target", noticing it in particular

module Distillery
  # onvert from character entity references
  CHARREF = {
    '&nbsp;' => ' ',
    '&lt;'   => '<',
    '&gt;'   => '>',
    '&amp;'  => '&',
    '&laquo;'=> "\xc2\xab",
    '&raquo;'=> "\xc2\xbb",
  }

  # Default option parameters.
  DEFAULT = {
    :threshold => 100,                                        # threhold for score of the text
    :min_length => 80,                                        # minimum length of evaluated blocks
    :decay_factor => 0.73,                                    # decay factor for block score
    :continuous_factor => 1.62,                               # continuous factor for block score ( the larger, the harder to continue )
    :punctuation_weight => 10,                                # score weight for punctuations
    :punctuations => /(\343\200[\201\202]|\357\274[\201\214\216\237]|\.[^A-Za-z0-9]|,[^0-9]|!|\?)/,
                                                              # punctuation characters
    :waste_expressions => /Copyright|All Rights Reserved/i,   # characteristic keywords including footer
    :debug => false,                                          # if true, output block information to stdout
  }
end
