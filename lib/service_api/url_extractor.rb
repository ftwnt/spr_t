module ServiceApi
  class UrlExtractor
    MULTIPLE_PAGES_URI_PATTERN = /page=(?<pages>\d(-\d)?)/.freeze
    FIRST_MULTIPLE_PAGES_PARAM = '&page=1-2'.freeze

    attr_reader :encoded_content

    def initialize(encoded_content:)
      @encoded_content = encoded_content
    end

    def perform
      url = parsed_content.keys
                          .find { |key| key =~ /#{api_endpoint_pattern}/ }
                          .gsub(/^G\./, '')
                          .gsub(/&a;/, '&')

      multiple_pages_for(url: url)
    end

    private

    def decoded_symbols_content
      encoded_content.gsub(/&q;/, '"')
    end

    def parsed_content
      @parsed_content ||= JSON.parse(decoded_symbols_content)
    end

    def api_endpoint_pattern
      Regexp.quote('https://xl-catalog-api.rozetka.com.ua/v2/goods/get?')
    end

    def multiple_pages_for(url:)
      pages_param = url =~ MULTIPLE_PAGES_URI_PATTERN

      return url.gsub("page=#{Regexp.last_match(:pages)}", 'page=1-2') if pages_param

      url = url.chop if url =~ /^.+\/$/
      url + FIRST_MULTIPLE_PAGES_PARAM
    end
  end
end
