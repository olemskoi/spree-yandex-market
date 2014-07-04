module Export

  class ActivizmExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=activizm&utm_medium=activizm&utm_campaign=activizm'
    end

    protected

    def offer_vendor_model(xml, product)
      variant = product.first_variant
      variants = product.variants.select { |v| v.count_on_hand > 0 }
      images = product.images.limit(10)
      gender = case product.gender
      when 1 then 'M'
      when 2 then 'W'
      else nil
      end

      opt = { id: product.id, available: true }
      model = model_name(product, variant)
      xml.offer(opt) do
        xml.url "http://#{@host}/id/#{product.id}#{@utms}"
        xml.price variant.price
        xml.old_price variant.old_price if variant.old_price.to_i > 0
        xml.currencyId currency_id
        xml.categoryId product_category_id(product)
        images.each do |image|
          xml.picture image_url(image)
        end
        xml.delivery true
        xml.local_delivery_cost @config.preferred_local_delivery_cost
        xml.vendor product.brand.name if product.brand
        xml.vendorCode product.sku
        model = []
        model << product.brand.name if product.brand.present?
        model << product.name
        xml.model model.join(' ')
        xml.description product_description(product) if product_description(product)
        xml.manufacturer_warranty true
        xml.country_of_origin product.country.name if product.country

        cnt = 0
        variants.each do |variant|
          cnt += 1 if variant_size(variant) or variant_color(variant)
        end

        if cnt > 0
          xml.variantList do
            variants.each do |variant|
              size = variant_size(variant)
              color = variant_color(variant)
              if size && color
                xml_type = "color_and_size"
              elsif size
                xml_type = "size"
              elsif color
                xml_type = "color"
              end

              xml.varint(type: xml_type) do
                variant.option_values.each do |ov|
                  opt = {}
                  if ov.option_type.xml_type.include?('size')
                    opt[:system] =  ov.option_type.xml_system if ov.option_type.try(:xml_system).present?
                    opt[:category] =  ov.option_type.xml_name if ov.option_type.try(:xml_name).present?
                    opt[:gender] = gender if gender
                    xml.size(ov.xml_presentation, opt)
                  elsif ov.option_type.xml_type.include?('color')
                    xml.color(ov.xml_presentation, opt)
                  end
                end
                xml.offerId variant.id
              end
            end
          end
        end

      end

    end

    def variant_size(variant)
      variant.option_values.find do |ov|
        ov && ov.option_type.xml_type.include?('size') rescue nil
      end
    end

    def variant_color(variant)
      variant.option_values.find do |ov|
        ov && ov.option_type.xml_type.include?('color') rescue nil
      end
    end



  end

end
