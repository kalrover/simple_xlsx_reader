# frozen_string_literal: true

module SimpleXlsxReader
  class Loader
    # For performance reasons, excel uses an optional SpreadsheetML feature
    # that puts all strings in a separate xml file, and then references
    # them by their index in that file.
    #
    # http://msdn.microsoft.com/en-us/library/office/gg278314.aspx
    class SharedStringsParser < Nokogiri::XML::SAX::Document
      def self.parse(file)
        new.tap do |parser|
          Nokogiri::XML::SAX::Parser.new(parser).parse(file)
        end.result
      end

      def initialize
        @result = []
        @composite = false
        @extract = false
        @phonetic = false
      end

      attr_reader :result

      def start_element(name, _attrs = [])
        case name
        when 'si' then @current_string = +"" # UTF-8 variant of String.new
        when 't' then @extract = true
        # https://learn.microsoft.com/ja-jp/openspecs/office_standards/ms-oe376/3251559a-3f8e-48b2-98b8-fcc85c63c2a4
        when 'rPh' then @phonetic = true
        end
      end

      def characters(string)
        return unless @extract
        return if @phonetic

        @current_string << string
      end

      def end_element(name)
        case name
        when 't' then @extract = false
        when 'si' then @result << @current_string
        when 'rPh' then @phonetic = false
        end
      end
    end
  end
end
