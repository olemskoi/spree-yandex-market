# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class RetailRocketExporter < YandexMarketExporter

    def initialize
    end

    protected

    def preferred_category
      Taxon.find_by_name(Spree::YandexMarket::Config.get(:category_for_retail_rocket))
    end

    def product_category_id(product)
      product.cat.id
    end

    def offer_vendor_model(xml, product)
      variant = product.first_variant
      images = product.images.limit(10)
      model = model_name(product, variant)
      xml.offer(type: 'vendor.model', available: true, id: product.id) do
        xml.url "#{@host}/id/#{product.id}"
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

    def minimal_price(product)
      product.variants.map(&:price).min
    end

  end
end
