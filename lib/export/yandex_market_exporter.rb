# encoding: utf-8


# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class YandexMarketExporter
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::SanitizeHelper

    attr_accessor :host, :currencies

    MIN_ORDER_AMOUNT = 500

    def initialize
      @utms = '?utm_source=yandex&utm_medium=market&utm_campaign=market'
    end

    def helper
      @helper ||= ApplicationController.helpers
    end
    
    def export
      @config = Spree::YandexMarket::Config.instance
      @host = @config.preferred_url.sub(%r[^http://],'').sub(%r[/$], '')

      @currencies = @config.preferred_currency.split(';').map{ |x| x.split(':') }
      @currencies.first[1] = 1
      
      @preferred_category = preferred_category
      unless @preferred_category.export_to_yandex_market
        raise "Preferred category <#{@preferred_category.name}> not included to export"
      end

      @categories = @preferred_category.descendants.where(:export_to_yandex_market => true)

      @categories_ids = @categories.collect { |x| x.id }
      
      Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.doc.create_internal_subset('yml_catalog', nil, 'shops.dtd')

        xml.yml_catalog({:date => Time.now.to_s(:ym)}.merge(namespaces)) {
          xml.shop { # описание магазина
            xml.name    @config.preferred_short_name
            xml.company @config.preferred_full_name
            xml.url     path_to_url('')
            
            xml.currencies { # описание используемых валют в магазине
              @currencies && @currencies.each do |curr|
                opt = { :id => curr.first, :rate => curr[1] }
                opt.merge!({ :plus => curr[2] }) if curr[2] && ["CBRF","NBU","NBK","CB"].include?(curr[1])
                xml.currency(opt)
              end
            }        
            
            xml.categories { # категории товара
              @categories_ids && @categories.each do |cat|
                @cat_opt = { :id => cat.id }
                @cat_opt.merge!({ :parentId => cat.parent_id }) if cat.level > 1 && cat.parent_id.present?
                xml.category(@cat_opt){ xml  << cat.name }
              end
            }

            xml.offers { # список товаров
              products.each do |product|
                offer_vendor_model(xml, product) 
              end
            }
          }
        } 
      end.to_xml
    end
    
    protected
    
    def offer_vendor_model(xml, product)
      return unless product.brand.present? # 'vendor' element is required

      variants = product.variants.select { |v| v.count_on_hand > 0 }
      count = variants.length
      images = product.images.limit(10)

      gender = case product.gender
        when 1 then 'Мужской'
        when 2 then 'Женский'
        else ''
      end

      variants.each do |variant|
        opt = { :type => 'vendor.model', :available => true }

        opt[:id] = variant.id
        opt[:group_id] = product.id if count > 1

        model = model_name(product)

        xml.offer(opt) do
          xml.url "http://#{@host}/id/#{product.id}#{@utms}"
          xml.price variant.price
          xml.oldprice variant.old_price if variant.old_price.to_i > 0
          xml.currencyId currency_id
          xml.categoryId product_category_id(product)
          xml.market_category market_category(product)
          images.each do |image|
            xml.picture image_url(image)
          end
          xml.delivery true
          xml.vendor product.brand.name
          xml.vendorCode product.sku
          if add_alt_vendor? && product.brand && product.brand.alt_displayed_name.present?
            xml.vendorAlt product.brand.alt_displayed_name
          end
          xml.model model
          xml.description product_description(product) if product_description(product)
          if variant.price < MIN_ORDER_AMOUNT
            xml.sales_notes "Минимальная сумма заказа - #{MIN_ORDER_AMOUNT} руб."
          end
          xml.country_of_origin product.country.name if product.country
          variant.option_values.each do |ov|
            unless ov.presentation == 'Без размера'
              unit = product.size_table ? product.size_table.standarted_size_table : 'BRAND'
              xml.param ov.presentation, :name => ov.option_type.presentation, :unit => unit
            end
          end
          xml.param product.colour, :name => 'Цвет'
          xml.param gender, :name => 'Пол' if gender.present?
          xml.param product.localized_age, :name => 'Возраст' if product.age
          xml.param product.picture_type, :name => 'Тип рисунка' if product.picture_type
          additional_params_for_offer(xml, product, variant)
        end
      end
    end

    def path_to_url(path)
      "http://#{@host.sub(%r[^http://],'')}/#{path.sub(%r[^/],'')}"
    end

    def image_url(image)
      "#{asset_host(image.to_s)}/#{CGI.escape(image.attachment.url(:large, false))}"
    end

    def asset_host(source)
      "http://assets0#{(1 + source.hash % 5).to_s + '.' + @host}"
    end

    def preferred_category
      Taxon.find_by_name(@config.preferred_category)
    end

    def product_category_id(product)
      if product.yandex_market_category_id
        product.yandex_market_category_id
      else
        product.cat.yandex_market_category_id if product.cat && product.cat.yandex_market_category_id
      end
    end

    def product_description(product)
      strip_tags(product.description) if product.description
    end
    
    def market_category(product)
      product.market_category if product.market_category.present?
    end

    def add_alt_vendor_to_model_name?;true;end
    def add_alt_vendor?;false;end

    def products
      products = Product.active.not_gifts.master_price_gte(0.001)
      products.uniq.select do |p|
        p.has_stock? && p.export_to_yandex_market && p.yandex_market_category_including_catalog &&
            p.yandex_market_category_including_catalog.export_to_yandex_market
      end
    end

    def model_name(product)
      model = []
      if add_alt_vendor_to_model_name? && product.brand && product.brand.alt_displayed_name.present?
        model << "(#{product.brand.alt_displayed_name})"
      end
      model << product.name
      
      if @config.preferred_extra_model == "sizes"
        sizes = []
        product.variants.each do |variant|
          variant.option_values.each do |val|
            sizes << val.presentation if val.presentation.present?
          end
        end
        model << "(%s)" % sizes.uniq.join(', ')
      else
        model << "(#{I18n.t("for_#{GENDER[product.try(@config.preferred_extra_model)].to_s}")})" if product.try(@config.preferred_extra_model).present?
      end
      
      model.join(' ')
    end

    def currency_id
      @currencies.first.first
    end

    def additional_params_for_offer(xml, product, variant)
      # nothing
    end

    def namespaces
      {}
    end

  end
end
