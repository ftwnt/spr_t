require 'mechanize'
require 'watir'
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
    scrapped_url = more_records_available? ? url : multiple_pages_url_for(url: url)
    content = parsed_content_for(url: scrapped_url)
    items = content.search('.goods-tile')

    return 'Nothing has been found' if items.empty?

    items.map do |item|
      ItemParser.new(item: item).process
    end
  end

  # private

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
end
