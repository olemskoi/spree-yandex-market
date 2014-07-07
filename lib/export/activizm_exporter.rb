# encoding: utf-8

module Export

  class ActivizmExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=activizm&utm_medium=activizm&utm_campaign=activizm'
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
                                        next if Product.where(yandex_market_category_id: cat.id).count == 0
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
      variant = product.first_variant
      variants = product.variants.select { |v| v.count_on_hand > 0 }
      images = product.images.limit(10)
      gender = case product.gender
      when 1 then 'M'
      when 2 then 'W'
      when 3 then 'J'
      when 4 then 'C'
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
