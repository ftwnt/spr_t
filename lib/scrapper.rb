require 'mechanize'
require 'watir'

class Scrapper
  attr_reader :url

  def initialize(url:)
    @url = url
  end

  def perform
    parsed_content
  end

  # private

  def parsed_content
    @content = Mechanize::Page.new(nil,
                                   {'content-type'=>'text/html'},
                                   preloaded_js_content,
                                   nil,
                                   agent)
  end

  def preloaded_js_content
    js_page_preloader.goto(url)
    js_page_preloader.element(css: '.js_content')
                     .wait_until(&:present?)
                     .html
  end

  def agent
    @agent ||= Mechanize.new
  end

  def js_page_preloader
    @preloader ||= Watir::Browser.new :chrome, headless: true
  end
end
