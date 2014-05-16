# encoding: utf-8
module Export
  class SegmentoExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=segmento&utm_medium=segmento&utm_campaign=segmento'
    end

    protected

    def offer_vendor_model(xml, product)
      variant = product.first_variant
      images = product.images.limit(10)
      gender = case product.gender
                 when 1 then 'Мужской'
                 when 2 then 'Женский'
                 else ''
               end

      opt = { id: product.id, type: 'vendor.model', available: true }
      model = model_name(product)
      xml.offer(opt) do
        xml.url "http://#{@host}/id/#{product.id}#{@utms}"
        xml.price variant.price
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
        xml.model model
        xml.description product_description(product) if product_description(product)
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

    def additional_params_for_offer(xml, product, variant)
      xml.old_price variant.old_price if variant && variant.old_price.to_i > 0
    end

  end
end
