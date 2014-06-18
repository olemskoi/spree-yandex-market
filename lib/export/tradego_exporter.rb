# encoding: utf-8
require 'nokogiri'

module Export
  class TradegoExporter < YandexMarketExporter

    def initialize
    end

    def export
      config = Spree::YandexMarket::Config.instance

      @host = config.preferred_url.sub(%r[^http://],'').sub(%r[/$], '')

      preferred_category = Taxon.find_by_name(config.preferred_category)
      categories = preferred_category.self_and_descendants.where(export_to_yandex_market: true)

      Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
        xml.doc.create_internal_subset('yml_catalog', nil, 'shops.dtd')
        xml.yml_catalog(date: Time.now.to_s(:ym)) do
          xml.shop do
            xml.title config.preferred_short_name
            xml.company config.preferred_full_name
            xml.url path_to_url('')

            xml.currencies do
              xml.currency(id: 'RUR', rate: 1)
            end

            xml.categories do
              categories.each do |category|
                xml.category(id: category.id, parent_id: category.parent_id){ xml << category.name }
              end
            end

            xml.offers do
              cut_price_products.each do |product|
                offer_vendor_model(xml, product)
              end
              discount_products.each do |product|
                offer_vendor_model(xml, product)
              end
            end
          end
        end
      end.to_xml
    end
    
    protected

    def offer_vendor_model(xml, product)
      cheapest_variant = product.variants_including_master.select{ |v| available_variant?(v) }.
          sort_by(&:price).first
      xml.offer(id: product.id) do
        xml.url "http://#{@host}/id/#{product.id}#{utms}"
        xml.priceOld cheapest_variant.old_price
        xml.price cheapest_variant.price
        xml.currencyId 'RUR'
        xml.categoryId product_category_id(product)
        xml.region 'Россия'
        product.images.limit(10).each do |image|
          xml.picture image_url(image)
        end
        xml.type product.export_to_yandex_market ? 2 : 1
        xml.name model_name(product, variant)
        if product_description(product)
          xml.description product_description(product)
          xml.descriptionDefect product_description(product) unless product.export_to_yandex_market?
        end
        xml.vendor product.brand.name if product.brand
        xml.model model_name(product, variant)
        cheapest_variant.option_values.each do |ov|
          unless ov.presentation == 'Без размера'
            unit = product.size_table ? product.size_table.standarted_size_table : 'BRAND'
            xml.param ov.presentation, name: ov.option_type.presentation, unit: unit
          end
        end
      end
    end

    def utms
      '?utm_source=tradego&utm_medium=tradego&utm_campaign=tradego'
    end

    # def model_name(product)
    #   model = []
    #   model << product.brand.name if product.brand.present?
    #   model << product.name
    #   model.join(' ')
    # end

    def old_price_products(cut_price)
      products = Product.active.not_gifts.master_price_gte(0.001)
      products.uniq.select do |p|
        p.export_to_yandex_market != cut_price &&
            p.variants_including_master.select{ |v| available_variant?(v) }.length > 0
      end
    end

    def cut_price_products
      old_price_products(true)
    end

    def discount_products
      old_price_products(false)
    end

    def available_variant?(variant)
      variant.old_price.present? && variant.old_price > 0 && variant.count_on_hand.present? && variant.count_on_hand > 0
    end

  end
end
