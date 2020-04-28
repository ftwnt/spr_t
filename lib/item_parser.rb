class ItemParser
  AVAILABILITY_STATUSES = %w[available limited].freeze

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
    item[:href]
  end

  def title
    item[:title]
  end

  def price
    item[:price]
  end

  def reviews
    item[:comments_amount]
  end

  def availability
    AVAILABILITY_STATUSES.include? item[:sell_status]
  end
end
