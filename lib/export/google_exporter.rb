# encoding: utf-8

# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class GoogleExporter < YandexMarketExporter

    def initialize
    end

    def export
      config = Spree::YandexMarket::Config.instance
      @host = config.preferred_url.sub(%r[^http://],'').sub(%r[/$], '')
      Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.rss({ version: '2.0' }.merge(namespaces)) do
          xml.channel do
            xml.title config.preferred_short_name
            xml.link path_to_url('')
            xml.description config.preferred_full_name
            products.each do |product|
              offer_vendor_model(xml, product)
            end
          end
        end
      end.to_xml
    end

    protected

    def offer_vendor_model(xml, product)
      product_image = product.images.first
      if product_image.present?
        variants = product.variants.select { |v| v.count_on_hand > 0 && v.export_to_yandex_market? }
        variants_count = variants.count
        variants.each do |variant|
          xml.item do
            xml.title model_name(product)
            xml.link "http://#{@host}/id/#{product.id}#{utms}"
            xml.description product_description(product)
            xml['g'].id variant.id
            xml['g'].condition 'new'
            if variant.old_price.to_i > 0
              xml['g'].price "#{variant.old_price} RUB"
              xml['g'].sale_price "#{variant.price} RUB"
            else
              xml['g'].price "#{variant.price} RUB"
            end
            xml['g'].availability(variant.available? ? 'in stock' : 'out of stock')
            xml['g'].image_link image_url(product_image, true)
            xml['g'].brand product.brand.name if product.brand
            xml['g'].mpn product.sku
            if product.cat && product.cat.google_merchant_category
              names = product.cat.google_merchant_category.ancestors.reject{ |a| a.level.zero? }.map{ |a| a.name }
              names << product.cat.google_merchant_category.name
              category_name = names.join(' > ')
              xml['g'].google_product_category category_name
              xml['g'].product_type category_name
            end
            ov = variant.option_values.first
            if ov && ov.presentation != 'Без размера'
              xml['g'].item_group_id product.id
              xml['g'].size ov.presentation
            end
            if ov
              if ov.google_color.present?
                xml['g'].color ov.google_color.name
              elsif product.google_color.present?
                xml['g'].color product.google_color.name
              end
            end
            if product.gender.present?
              xml['g'].gender gender(product)
            end
            if variant.age_group.present? && variant.age_group != 'none'
              xml['g'].age_group variant.age_group
            end
          end
        end
      end
    end

    def utms
      '?utm_source=google&utm_medium=merchants&utm_campaign=merchants'
    end

    def namespaces
      { 'xmlns:g' => 'http://base.google.com/ns/1.0' }
    end

    def product_description(product)
      if product.description.present? or product.short_description.present?
        strip_tags(product.short_description.to_s + ' ' + product.description.to_s).strip
      else
        model_name(product)
      end
    end

    def model_name(product)
      model = []
      if product.age_restriction.present? && product.age_restriction != 'none'
        model << "(#{Product::AGE_RESTRICTIONS[product.age_restriction]})"
      end
      model << product.brand.name if product.brand.present?
      model << product.name
      model.join(' ')
    end

    def gender(product)
      case product.gender
        when 1 then 'male'
        when 2 then 'female'
        else 'unisex'
      end
    end

  end
end
