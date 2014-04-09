# encoding: utf-8

module Export
  class AlyticsExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=alytics&utm_medium=alytics&utm_campaign=alytics'
    end

    protected

    def offer_vendor_model(xml, product)
      images = product.images.limit(10)
      gender = case product.gender
                 when 1 then 'Мужской'
                 when 2 then 'Женский'
                 else ''
               end

      return unless product_price(product).present? && product_category_id(product).present?

      xml.offer(type: 'vendor.model', available: product.has_stock?, id: product.id) do
        xml.url "http://#{@host}/id/#{product.id}#{@utms}"
        xml.price product_price(product)
        xml.currencyId currency_id
        xml.categoryId product_category_id(product)
        xml.market_category market_category(product)
        images.each do |image|
          xml.picture image_url(image)
        end
        xml.delivery true
        xml.vendor product.brand.name if product.brand
        if add_alt_vendor? && product.brand && product.brand.alt_displayed_name.present?
          xml.vendorAlt product.brand.alt_displayed_name
        end
        xml.vendorCode product.sku
        xml.model model_name(product)
        xml.description product_description(product) if product_description(product)
        if product.country
          xml.country_of_origin product.country.name
          xml.param product.country.name, name: 'Страна'
        end
        if product.produced_country
          xml.param product.produced_country.name, name: 'Произведено'
        end
        xml.param product.colour, :name => 'Цвет'
        xml.param product.vendor_color, name: 'Цвет по поставщику' if product.vendor_color.present?
        xml.param gender, name: 'Пол' if gender.present?
        xml.param product.localized_age, name: 'Возраст' if product.age
        xml.param product.picture_type, name: 'Тип рисунка' if product.picture_type.present?
        if product.orthopedic_properties.present?
          xml.param product.orthopedic_properties.map(&:name).join(', '), name: 'Ортопедические свойства'
        end
        product.product_properties.each do |property|
          xml.param property.value, name: property.property.name if product.picture_type
        end
      end
    end

    def product_price(product)
      product.variants.where('variants.count_on_hand > 0').map(&:price).min
    end

    def preferred_category
      Taxon.find_by_name(@config.preferred_category_for_alytics)
    end

    def product_category_id(product)
      product.cat.id if product.cat.present?
    end

    def market_category(product)
      product.internal_market_category
    end

    def model_name(product)
      model = []
      if add_alt_vendor_to_model_name? && product.brand && product.brand.alt_displayed_name.present?
        model << "(#{product.brand.alt_displayed_name})"
      end
      model << product.name
      model.join(' ')
    end

    def add_alt_vendor_to_model_name?;false;end
    def add_alt_vendor?;true;end

  end
end