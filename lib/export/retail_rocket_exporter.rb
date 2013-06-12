# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class RetailRocketExporter < YandexMarketExporter

    def initialize
    end
    
    protected
    
    def offer_vendor_model(xml, product)
      images = product.images.limit(10)

      # TODO refactor: extract method
      model = []
      if add_alt_vendor_to_model_name? && product.brand && product.brand.alt_displayed_name.present?
        model << "(#{product.brand.alt_displayed_name})"
      end
      model << product.name
      model << "(#{I18n.t("for_#{GENDER[product.gender].to_s}")})" if product.gender.present?
      model = model.join(' ')

      xml.offer(type: 'vendor.model', available: true, id: product.id) do
        xml.url "http://#{@host}/id/#{product.id}"
        xml.price 1 # TODO change this
        xml.currencyId @currencies.first.first # TODO first.first WTF?
        xml.categoryId product_category_id(product)
        images.each do |image|
          xml.picture image_url(image)
        end
        xml.vendor product.brand.name if product.brand
        xml.model model
      end
    end

  end
end
