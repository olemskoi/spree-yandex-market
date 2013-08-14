# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class GoogleExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=google&utm_medium=merchants&utm_campaign=merchants'
    end
    
    protected

    def namespaces
      { 'xmlns:g' => 'http://base.google.com/ns/1.0' }
    end

    def additional_params_for_offer(xml, product)
      if product.cat && product.cat.google_merchant_category
        names = product.cat.google_merchant_category.ancestors.reject{ |a| a.level.zero? }.map{ |a| a.name }
        names << product.cat.google_merchant_category.name
        category_name = names.join(' > ')
        xml['g'].google_product_category category_name
        xml['g'].product_type category_name
      end
    end

    def product_description(product)
      if product.description
        strip_tags(product.description)
      else
        model_name(product)
      end
    end

  end
end
