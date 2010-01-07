require "benchmark"

module ProfanityFilter
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def profanity_filter!(*attr_names)
      option = attr_names.pop[:method] if attr_names.last.is_a?(Hash)
      attr_names.each { |attr_name| setup_callbacks_for(attr_name, option) }
    end

    def profanity_filter(*attr_names)
      option = attr_names.pop[:method] if attr_names.last.is_a?(Hash)

      attr_names.each do |attr_name|
        instance_eval do
          define_method "#{attr_name}_clean" do; ProfanityFilter::Base.clean(self[attr_name.to_sym], option); end
          define_method "#{attr_name}_original"do; self[attr_name]; end
          alias_method attr_name.to_sym, "#{attr_name}_clean".to_sym
        end
      end
    end

    def setup_callbacks_for(attr_name, option)
      before_validation do |record|
        record[attr_name.to_sym] = ProfanityFilter::Base.clean(record[attr_name.to_sym], option)
      end
    end
  end

  class Base
    cattr_accessor :replacement_text, :dictionary_file, :dictionary
    @@replacement_text = '@#$%'
    @@dictionary_file  = File.join(File.dirname(__FILE__), '../config/dictionary.yml')
    @@dictionary       = YAML.load_file(@@dictionary_file)

    class << self
      def clean(text, replace_method = '')
        return text if text.blank?
        @replace_method = replace_method.to_s
        text.split(/(\s)/).collect{ |word| clean_word(word) }.join
      end

      def clean_word(word)
        return word unless(word.strip.size > 2)

        if word.index(/[\W]/)
          word = word.split(/(\W)/).collect{ |subword| clean_word(subword) }.join
          concat = word.gsub(/\W/, '')
          word = concat if is_banned? concat
        end

        banned = is_banned?(word)
        banned ? replacement(word, banned) : word
      end

      def replacement(word, banned)
        case @replace_method
        when 'dictionary'
          dictionary[banned]
        when 'vowels'
          word.gsub(/[aeiou]/i, '*')
        when 'hollow'
          word[1..word.size-2] = '*' * (word.size-2) if word.size > 2
          word
        else
          replacement_text
        end
      end

      def is_banned?(word = '')
        word = word.downcase
        return word if dictionary.include?(word) # fast whole-word lookup first
        # check prefixes of 3 letters and more
        word.length.downto(3) do |len|
          prefix = word[0...len] + '*'
          return prefix if dictionary.include?(prefix)
        end
        nil
      end
    end
  end
end
