class ItemParser
  AVAILABILITY_CSS_MARKS = %w[
    .goods-tile__availability_type_available
    goods-tile__availability_type_limited
  ].freeze

  attr_reader :item

  def initialize(item:)
    @item = item
  end

  def process
    {
      url: url,
      title: title,
      price: price,
      reviews_count: reviews,
      availability: availability
    }
  end

  private

  def url
    item_heading.first[:href]
  end

  def title
    item_heading.first[:title]
  end

  def price
    item.search('.goods-tile__price-value')
        .first
        &.text
        &.gsub(/\s/, '')
        &.to_i
  end

  def reviews
    item.search('.goods-tile__rating .goods-tile__reviews-link')
        .text
        .to_i
  end

  def availability
    !item.search(AVAILABILITY_CSS_MARKS.join(', ')).empty?
  end

  def item_heading
    item.search('.goods-tile__heading')
  end
end
