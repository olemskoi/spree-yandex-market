# encoding: utf-8

require 'nokogiri'

module Export
  class YandexMarketExporter
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::SanitizeHelper

    attr_accessor :host, :currencies

    def initialize
      @utms = '?utm_source=yandex&utm_medium=market&utm_campaign=market'
    end

    def helper
      @helper ||= ApplicationController.helpers
    end

    def export
      @config = Spree::YandexMarket::Config.instance
      @host = @config.preferred_url.sub(%r[^http://], '').sub(%r[/$], '')

      @currencies = @config.preferred_currency.split(';').map { |x| x.split(':') }
      @currencies.first[1] = 1

      @preferred_category = preferred_category
      unless @preferred_category.export_to_yandex_market
        raise "Preferred category <#{@preferred_category.name}> not included to export"
      end

      market_categories_with_products = @preferred_category.descendants.where(export_to_yandex_market: true).joins(:yandex_market_products).uniq

      market_categories_with_parents = market_categories_with_products.map(&:self_and_ancestors).flatten.uniq

      categories_with_market_categories = Taxonomy.catalog.root.descendants.joins(:yandex_market_category).uniq.map(&:yandex_market_category).uniq

      @categories = (market_categories_with_parents + categories_with_market_categories).uniq

      @categories_ids = @categories.collect { |x| x.id }

      Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
        xml.doc.create_internal_subset('yml_catalog', nil, 'shops.dtd')

        xml.yml_catalog({date: Time.now.to_s(:ym)}.merge(namespaces)) {
          xml.shop {# описание магазина
            xml.name @config.preferred_short_name
            xml.company @config.preferred_full_name
            xml.url path_to_url('')

            xml.currencies {# описание используемых валют в магазине
              @currencies && @currencies.each do |curr|
                opt = {id: curr.first, rate: curr[1]}
                opt.merge!({plus: curr[2]}) if curr[2] && ["CBRF", "NBU", "NBK", "CB"].include?(curr[1])
                xml.currency(opt)
              end
            }

            xml.categories {# категории товара
              @categories_ids && @categories.each do |cat|
                @cat_opt = {id: cat.id}
                @cat_opt.merge!({parentId: cat.parent_id}) if cat.level > 1 && cat.parent_id.present?
                xml.category(@cat_opt) { xml << cat.name }
              end
            }

            xml.offers {# список товаров
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
      return if product.bulky? # не выгружаем крупногабаритные товары
      return if product.name.mb_chars.downcase.include?('уценка')
      brand = product.brand
      return unless brand.present? # 'vendor' element is required

      variants = product.variants.select { |v| v.count_on_hand > 0 }
      count = variants.length
      images = product.images.limit(10)

      gender = case product.gender
                 when 1 then
                   'Мужской'
                 when 2 then
                   'Женский'
                 else
                   ''
               end

      variants.each do |variant|
        next unless variant.export_to_yandex_market?

        available = virtual_available_for_delivery ? !variant.virtual_availability : true

        opt = {type: 'vendor.model', available: available}

        opt[:id] = variant.id
        opt[:group_id] = product.id if count > 1

        model = model_name(product, variant)

        price = variant.price
        if price.to_i > 1
          xml.offer(opt) do
            xml.url "http://#{@host}/id/#{product.id}#{@utms}"
            xml.price price
            old_price = variant.old_price
            if old_price.to_i > 0 and price / old_price <= 0.95
              xml.oldprice old_price
            end
            xml.currencyId currency_id
            xml.categoryId product_category_id(product)
            xml.market_category market_category(product)
            images.each do |image|
              xml.picture image_url(image)
            end
            xml.delivery true
            xml.vendor brand.name
            xml.vendorCode product.sku
            if add_alt_vendor? && brand && brand.alt_displayed_name.present?
              xml.vendorAlt brand.alt_displayed_name
            end
            xml.model model
            xml.description product_description(product) if product_description(product)
            xml.sales_notes "Минимальная сумма заказа - #{APP_CONFIG['min_pickup_price']} руб."
            xml.country_of_origin product.country.name if product.country
            xml.barcode variant.barcode if variant.barcode.present?
            variant.option_values.each do |ov|
              unless ov.presentation == 'Без размера'
                unit = product.size_table ? product.size_table.standarted_size_table : 'BRAND'
                size_value = ov.yml_presentation.present? ? ov.yml_presentation : ov.presentation
                xml.param size_value, name: ov.option_type.presentation, unit: unit
              end
            end
            xml.param product.colour, name: 'Цвет'
            xml.param gender, name: 'Пол' if gender.present?
            xml.param product.localized_age, name: 'Возраст' if product.age
            xml.param product.picture_type, name: 'Тип рисунка' if product.picture_type
            xml.param series(product), name: 'Линейка' if series(product).present?
            xml.param age_from(variant), name: 'Возраст от', unit: 'месяцев' if age_from(variant).present?
            xml.param age_to(variant), name: 'Возраст до', unit: 'месяцев' if age_to(variant).present?
            xml.param variant.width, name: 'Ширина', unit: 'см' if variant.width.present?
            xml.param variant.height, name: 'Высота', unit: 'см' if variant.height.present?
            xml.param variant.depth, name: 'Глубина', unit: 'см' if variant.depth.present?
            xml.param variant.weight, name: 'Вес', unit: 'кг' if variant.weight.present?
            product.product_properties.each do |product_property|
              yandex_name = product_property.property.yandex_name
              yandex_tag = product_property.property.yandex_tag
              name = yandex_name.present? ? yandex_name : product_property.property.name
              if yandex_tag.present?
                xml.send(yandex_tag.to_sym, product_property.value, name: name)
              else
                xml.param product_property.value, name: name
              end
            end
            if product.orthopedic_properties.present?
              xml.param product.orthopedic_properties.map(&:name).join(', '), name: 'Ортопедические свойства'
            end
            xml.param seasons(product), name: 'Сезоны' if seasons(product).present?
            additional_params_for_offer(xml, product, variant)
          end
        end
      end
    end

    def path_to_url(path)
      "http://#{@host.sub(%r[^http://], '')}/#{path.sub(%r[^/], '')}"
    end

    def image_url(image, wowm = false)
      "#{asset_host(image.to_s)}#{image.attachment.url((wowm ? :large_wowm : :large), false)}"
    end

    def asset_host(source)
      # "http://assets0#{(1 + source.hash % 5).to_s + '.' + @host}"
      "http://#{@host}"
    end

    def preferred_category
      Taxon.find_by_name(@config.preferred_category)
    end

    def product_category_id(product)
      if product.yandex_market_category
        product.yandex_market_category_id
      else
        product.cat.yandex_market_category_id if product.cat && product.cat.yandex_market_category
      end
    end

    def product_description(product)
      if product.description.present? or product.short_description.present?
        strip_tags(product.short_description.to_s + ' ' + product.description.to_s).strip
      end
    end

    def market_category(product)
      product.market_category if product.market_category.present?
    end

    def add_alt_vendor_to_model_name?;
      true;
    end

    def add_alt_vendor?;
      false;
    end

    def products
      # Много написано, зато выполянется за несколько секунд, в отличии от минуты до этого
      # Что делается в этом куске кода?
      # Нам нужно получить список товаров годных к выгрузке
      # Для этого должны быть выполнены следующие условия

      # Первым делом выбираем товары не являющиеся подарком, с ценой не менее минимальной,
      # в наличии и с вариантами отмеченными для экспорта

      min_product_price = APP_CONFIG['min_product_price']
      product_ids = Product.not_gifts.joins(:variants_including_master).
          where('variants.price >= ? and variants.count_on_hand > 0 and variants.export_to_yandex_market = ?',
                min_product_price, true).uniq.pluck(:id)

      # В категории товара должно стоять export_to_yandex_market = true
      # если у товара нет категории, то это условие пропускается

      product_with_cat_ids = Product.joins(:taxons).where(id: product_ids).
          where('taxons.permalink like ?', 'cat/%').uniq.pluck(:id)

      product_without_cat_ids = product_ids - product_with_cat_ids

      # т.к. у товара может быть несколько категорий, мы его исключим из списка,
      # даже если у одной из категорий отменён экспорт на Яндекс.Маркет
      product_with_cat_for_yandex_ids = Product.joins(:taxons).where(id: product_ids).
          where('taxons.export_to_yandex_market = ? and taxons.permalink like ?', true, 'cat/%').
          uniq.pluck(:id) - Product.joins(:taxons).where(id: product_ids).
              where('taxons.export_to_yandex_market = ? and taxons.permalink like ?', false, 'cat/%').uniq.pluck(:id)

      # также у товара либо его категории дожна быть установлена категория Янедкса,
      # у этой категории также должен быть включёт экспорт на яндекс

      yandex_categories_ids = Taxonomy.yandex_market.root.descendants.
                                       where(export_to_yandex_market: true).pluck(:id)

      products_with_ym_category_ids = Product.where(id: product_ids,
                                                    yandex_market_category_id: yandex_categories_ids).pluck(:id)

      product_with_cat_with_ymc_ids = Product.joins(:taxons).where('taxons.permalink like ?', 'cat/%').
                                where(taxons: {yandex_market_category_id: yandex_categories_ids}).uniq.pluck(:id)

      # из выборки исключаем товары отмечены как неимпортируемы на Яндекс

      product_not_for_yandex_ids = Product.where(export_to_yandex_market: false).pluck(:id)

      # наличие бренда у товара обязательно
      products_with_brand_ids = Product.joins(:taxons).where(id: product_ids).
          where('taxons.permalink like ?', 'brand/%').uniq.pluck(:id)

      filtered_product_ids = products_with_brand_ids &
          ((product_with_cat_for_yandex_ids + product_without_cat_ids) &
           (products_with_ym_category_ids + product_with_cat_with_ymc_ids) - product_not_for_yandex_ids)

      Product.where(id: filtered_product_ids).includes(:images, :taxons, :country, :size_table, :yandex_market_category,
                                                       :orthopedic_properties, product_properties: :property,
                                                       variants_including_master: [option_values: :option_type])
    end

    def model_name(product, variant)
      model = []
      model << product.name_with_brand
      if add_alt_vendor_to_model_name? && product.brand && product.brand.alt_name.present?
        model << "(#{product.brand.alt_name})"
      end
      if @config.present?
        if @config.preferred_extra_model == "sizes"
          variant.option_values.each do |ov|
            unless ov.presentation == 'Без размера'
              model << "[%s]" % ov.presentation
            end
          end
          # else
          #   model << "(#{I18n.t("for_#{GENDER[product.try(@config.preferred_extra_model)].to_s}")})" if product.try(@config.preferred_extra_model).present?
        end
      end

      model.join(' ')
    end

    def currency_id
      @currencies.first.first
    end

    def series(product)
      series_property = product.product_properties.find { |p| p.property.name.mb_chars.downcase == 'серия' }
      unless series_property.present?
        series_property = product.product_properties.find { |p| p.property.name.mb_chars.downcase == 'коллекция' }
      end
      series_property.value if series_property.present?
    end

    def age_from(variant)
      variant.age_from if variant.respond_to?(:age_from) && variant.age_from.present?
    end

    def age_to(variant)
      variant.age_to if variant.respond_to?(:age_to) && variant.age_to.present?
    end

    def seasons(product)
      product.season.map { |s| I18n.t(s) }.join(', ')
    end

    def additional_params_for_offer(xml, product, variant)
      # nothing
    end

    def namespaces
      {}
    end

    def virtual_available_for_delivery
      @virtual_available_for_delivery ||= @config.preferred_virtual_available_for_delivery
    end

  end
end
