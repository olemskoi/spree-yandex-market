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
        xml.model = model_name(product, variant)
        xml.description product_description(product) if product_description(product)
        xml.manufacturer_warranty true
        xml.country_of_origin product.country.name if product.country

        xml.variantList do
          variants.each do |variant|
            xml.varint(type: "size") do
              variant.option_values.each do |ov|
                opt = {system: "RU"}
                opt[:category] = market_category(product) if market_category(product)
                opt[:gender] = gender if gender
                xml.size(ov.presentation, opt)
                xml.offerId variant.id
              end
            end
          end
        end


      end

    end



  end

end
