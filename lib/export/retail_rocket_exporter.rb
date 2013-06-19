# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class RetailRocketExporter < YandexMarketExporter

    def initialize
    end
    
    protected
    
    def offer_vendor_model(xml, product)
      images = product.images.limit(10)
      model = model_name(product)
      xml.offer(type: 'vendor.model', available: true, id: product.id) do
        xml.url "http://#{@host}/id/#{product.id}"
        xml.price minimal_price(product)
        xml.currencyId currency_id
        xml.categoryId product_category_id(product)
        images.each do |image|
          xml.picture image_url(image)
        end
        xml.vendor product.brand.name if product.brand
        xml.model model
      end
    end

    def products
      products = Product.in_yandex_market_categories.active.not_gifts.master_price_gte(0.001)
      products.uniq.select { |p| p.yandex_market_category.export_to_yandex_market && p.export_to_yandex_market }
    end

    def minimal_price(product)
      product.variants.map(&:price).min
    end

  end
end
