require 'mechanize'
require 'watir'
require 'redis'

require './lib/api_url_extractor'
require './lib/item_parser'

class Scrapper
  MULTIPLE_PAGES_URI_PATTERN = /page=(?<pages>\d-\d)/.freeze
  FIRST_MULTIPLE_PAGES_PARAM = ';page=1-2'.freeze

  attr_reader :url, :agent, :store

  def initialize(url:)
    @url = url
    @agent = Mechanize.new
    @store = Redis.new
  end

  def perform
    puts goods_retrieval_url
    # restore_or_cache do
    #   scrapped_url = more_records_available? ? url : multiple_pages_url_for(url: url)
    #   content = parsed_content_for(url: scrapped_url)
    #   items = content.search('.goods-tile')
    #
    #   if items.empty?
    #     'Nothing has been found'
    #   else
    #     items.map { |item| ItemParser.new(item: item).process }
    #   end
    # end
  end

  def retrieve_and_uncache_results
    return unless (stored = retrieve_cached)

    result = Marshal.load stored

    return result if result.is_a? String

    puts 'URL Price Reviews Name'

    prepare_for_output(results: result).each do |item|
      puts [item[:url], item[:price], item[:reviews_count], item[:title]].join(' ')
    end

    store.del(cached_key)
  end

  private

  def page_content
    @page_content = agent.get(url)
  end

  def api_related_urls
    page_content.search('#rz-client-state').text
  end

  def goods_retrieval_url
    @goods_retrieval_url = ApiUrlExtractor.new(api_related_urls).perform
  end
  # def data_content
  #   unless data_items
  #     related_link = page_content.link_at(href: /#{request_related_uri}/)
  #     raise Mechanize::ElementNotFoundError unless related_link
  #     related_link.click
  #   end
  #
  #   data_items
  # end

  def multiple_pages_url_for(url:)
    pages_param = url =~ MULTIPLE_PAGES_URI_PATTERN

    return url.gsub("page=#{Regexp.last_match(:pages)}", 'page=1-2') if pages_param

    url = url.chop if url =~ /^.+\/$/
    url + FIRST_MULTIPLE_PAGES_PARAM
  end

  def restore_or_cache
    cached_result = retrieve_cached

    if cached_result
      Marshal.load cached_result
    else
      scrapped_data = yield
      store.set(cached_key, Marshal.dump(scrapped_data))
    end
  end

  def retrieve_cached
    url_store_key = cached_key
    store.get(url_store_key)
  end

  def cached_key
    "rozetka::#{url}"
  end

  def prepare_for_output(results:)
    results.select { |item| item[:availability] && item[:reviews_count] >= 1 }
           .sort_by { |item| [item[:reviews_count], item[:price]] }.reverse!
  end
end
