require 'mechanize'
require 'watir'
require 'redis'

require './lib/item_parser'

class Scrapper
  MORE_RECORDS_LINK_PATTERN = /^Показать ещё/.freeze
  MULTIPLE_PAGES_URI_PATTERN = /page=(?<pages>\d-\d)/.freeze
  SLASHED_URL_PATTERN = /^.+\/$/.freeze
  FIRST_MULTIPLE_PAGES_PARAM = ';page=1-2'.freeze

  attr_reader :url

  def initialize(url:)
    @url = url
  end

  def perform
    restore_or_cache do
      scrapped_url = more_records_available? ? url : multiple_pages_url_for(url: url)
      content = parsed_content_for(url: scrapped_url)
      items = content.search('.goods-tile')

      if items.empty?
        'Nothing has been found'
      else
        items.map { |item| ItemParser.new(item: item).process }
      end
    end
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

  def parsed_content_for(url:)
    Mechanize::Page.new(nil,
                        { 'content-type' => 'text/html' },
                        preloaded_js_content_for(url: url),
                        nil,
                        agent)
  end

  def preloaded_js_content_for(url:)
    js_page_preloader.goto(url)
    js_page_preloader.element(css: '.js_content')
                     .wait_until(&:present?)
                     .html
  end

  def more_records_available?
    parsed_content_for(url: url).link_with(text: MORE_RECORDS_LINK_PATTERN)
  end

  def multiple_pages_url_for(url:)
    pages_param = url =~ MULTIPLE_PAGES_URI_PATTERN

    return url.gsub("page=#{Regexp.last_match(:pages)}", 'page=1-2') if pages_param

    url.chop! if url =~ /^.+\/$/
    url + FIRST_MULTIPLE_PAGES_PARAM
  end

  def agent
    @agent ||= Mechanize.new
  end

  def js_page_preloader
    @js_page_preloader ||= Watir::Browser.new :chrome, headless: true
  end

  def store
    @store = Redis.new
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
