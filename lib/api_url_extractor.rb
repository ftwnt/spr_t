class ApiUrlExtractor
  API_ENDPOINT_PATTERN = "https://xl-catalog-api.rozetka.com.ua/v2/goods/get?".freeze

  attr_reader :encoded_content

  def initialize(encoded_content)
    @encoded_content = encoded_content
  end

  def perform
    parsed_content.keys
                  .find { |key| key =~ /#{API_ENDPOINT_PATTERN}/ }
                  .gsub(/^G\./, '')
                  .gsub(/&a;/, '&')
  end

  private

  def decoded_symbols_content
    encoded_content.gsub(/&q;/, '"')
  end

  def parsed_content
    @parsed_content ||= JSON.parse(decoded_symbols_content)
  end
end
