require 'test/unit'
require 'rubygems'
require 'yaml'
require 'activerecord'

require File.dirname(__FILE__) + '/../lib/profanity_filter'

class PrefixFilterTest < Test::Unit::TestCase

  PFB = ProfanityFilter::Base
  PROFANITY = "let's see abc XYZZYX now this is bad: abcABCDEFdef and this too: XYZZZZZZ and this aBcH4X0r1337"

  def setup
    PFB.dictionary["abc*"] = "a..."
    PFB.dictionary["xyz*"] = "x..."
  end

  def test_filter_replaces_words_by_prefix
    assert_equal( "let's see @\#$% @\#$% now this is bad: @\#$% and this too: @\#$% and this @\#$%",
                  PFB.clean(PROFANITY))
  end

  def test_filter_replaces_words_by_prefix_dictionary_method
    assert_equal( "let's see a... x... now this is bad: a... and this too: x... and this a...",
                  PFB.clean(PROFANITY, 'dictionary'))
  end

  def test_filter_replaces_words_by_prefix_hollow_method
    assert_equal( "let's see a*c X****X now this is bad: a**********f and this too: X******Z and this a**********7",
                  PFB.clean(PROFANITY, 'hollow'))
  end

  def test_filter_replaces_words_by_prefix_vowels_method
    assert_equal( "let's see *bc XYZZYX now this is bad: *bc*BCD*Fd*f and this too: XYZZZZZZ and this *BcH4X0r1337",
                  PFB.clean(PROFANITY, 'vowels'))
  end
end