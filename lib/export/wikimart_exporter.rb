# encoding: utf-8
module Export
  class WikimartExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=wikimart&utm_medium=yml&utm_campaign=yml'
    end

    protected

    def offer_vendor_model(xml, product)
      variants = product.variants.select { |v| v.count_on_hand > 0 && v.price > APP_CONFIG['min_pickup_price'] }
      count = variants.length
      images = product.images.limit(10)

      gender = case product.gender
                 when 1 then 'Мужской'
                 when 2 then 'Женский'
                 else ''
               end

      variants.each do |variant|
        next unless variant.export_to_yandex_market?
        opt = { :type => 'vendor.model', :available => true }

        opt[:id] = variant.id
        opt[:group_id] = product.id if count > 1

        model = model_name(product, variant)

        xml.offer(opt) do
          xml.url "http://#{@host}/id/#{product.id}#{@utms}"
          xml.price variant.price
          xml.currencyId currency_id
          xml.categoryId product_category_id(product)
          xml.market_category market_category(product)
          images.each do |image|
            xml.picture image_url(image, true)
          end
          xml.delivery true
          xml.vendor product.brand.name if product.brand
          if add_alt_vendor? && product.brand && product.brand.alt_displayed_name.present?
            xml.vendorAlt product.brand.alt_displayed_name
          end
          xml.vendorCode product.sku
          xml.model [model, product.sku].join(" ")
          xml.description product_description(product) if product_description(product)
          xml.country_of_origin product.country.name if product.country
          size = variant_size(variant)
          xml.param size.presentation, name: 'Размер', type: 'size', unit: 'RU' if size
          xml.param product.colour, name: 'Цвет', type: 'colour'
          xml.param gender, :name => 'Пол' if gender.present?
          xml.param product.localized_age, :name => 'Возраст' if product.age
          xml.param product.picture_type, :name => 'Тип рисунка' if product.picture_type
          additional_params_for_offer(xml, product, variant)
        end
      end
    end

    def variant_size(variant)
      variant.option_values.find do |ov|
        ov && ov.option_type.presentation.mb_chars.downcase.include?('размер')
      end
    end

    def preferred_category
      Taxonomy.wikimart.root
    end

    def product_category_id(product)
      category = product.cat
      if category
        category_with_wikimart = closest_category_with_wikimart(category)
        category_with_wikimart.wikimart_category.id if category_with_wikimart
      end
    end

    def market_category(product)
      category = product.cat
      if category
        category_with_wikimart = closest_category_with_wikimart(category)
        if category_with_wikimart
          categories_path = category_with_wikimart.wikimart_category.self_and_ancestors.map(&:name)
          categories_path.shift
          categories_path.join('/')
        end
      end
    end

    private

    def closest_category_with_wikimart(category)
      category.self_and_ancestors.reject{ |c| c.level == 0 }.reverse.find{ |c| c.wikimart_category.present? }
    end

  end
end