require 'mechanize'
require 'watir'
require 'redis'

require './lib/service_api/goods_retriever'
require './lib/service_api/url_extractor'
require './lib/item_parser'

class Scrapper
  attr_reader :url, :agent, :store

  def initialize(url:)
    @url = url
    @agent = Mechanize.new
    @store = Redis.new
  end

  def perform
    restore_or_cache do
      if retrieved_goods.empty?
        'Nothing has been found'
      else
        retrieved_goods.map { |item| ItemParser.new(item: item).process }
      end
    end
  end

  def retrieve_and_uncache_results
    return unless (stored = retrieve_cached)

    result = Marshal.load stored

    print_results(result: result)

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
    @goods_retrieval_url = ServiceApi::UrlExtractor.new(encoded_content: api_related_urls).perform
  end

  def retrieved_goods
    @retrieved_goods ||= ServiceApi::GoodsRetriever.new(url: goods_retrieval_url).perform
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

  def print_results(result:)
    if result.is_a? String
      puts(result)
      return
    end

    filtered_results = prepare_for_output(results: result)

    return if filtered_results.empty?

    puts 'URL Price Reviews Name'
    filtered_results.each do |item|
      puts [item[:url], item[:price], item[:reviews_count], item[:title]].join(' ')
    end
  end
end
