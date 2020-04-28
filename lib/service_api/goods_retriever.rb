module ServiceApi
  class GoodsRetriever
    attr_reader :url

    def initialize(url:)
      @url = url
    end

    def perform
      goods_ids_response = Net::HTTP.get URI(url)
      goods_ids = JSON.parse(goods_ids_response, symbolize_names: true)

      uri = URI(goods_details_request_url(goods_ids[:data][:ids]))

      goods_details_response = Net::HTTP.get(uri)

      JSON.parse(goods_details_response, symbolize_names: true)[:data]
    end

    def goods_details_endpoint
      'https://xl-catalog-api.rozetka.com.ua/v2/goods/getDetails'
    end

    def goods_details_request_params(ids)
      "product_ids=#{ids.join(',')}"
    end

    def goods_details_request_url(ids)
      [
        goods_details_endpoint,
        goods_details_request_params(ids)
      ].join('?')
    end
  end
end
