# encoding: utf-8

module Export
  class AlyticsCategoryExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=alytics&utm_medium=alytics&utm_campaign=alytics'
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

            xml.offers { # список категорий
              @categories.each do |category|
                offer_category(xml, category)
              end
            }
          }
        }
      end.to_xml
    end

    protected

    def offer_category(xml, category)
      category_names = ([category.name] + category.name.split(' ').compact).uniq
      products = Product.in_taxon category
      product_ids = products.map(&:id)
      variants = Variant.where(product_id: product_ids).is_not_master
      max_price = variants.map(&:price).max.to_i
      brands = Taxon.brands_by_category(category)

      brand_names = brands.map do |brand|
        if brand.alt_name.present?
          alt_names = brand.alt_name.include?(',') ? brand.alt_name.split(',') : brand.alt_name.split(' ').compact
          [brand.name, brand.alt_displayed_name] + alt_names
        else
          [brand.name, brand.alt_displayed_name]
        end
      end.flatten.uniq.compact.sort - ['']

      colours = products.map{|p| p.colour.to_s.mb_chars.downcase.to_s}.uniq
      vendor_colors = products.map{|p| p.vendor_color.to_s.mb_chars.downcase.to_s}.uniq

      colors = (colours + vendor_colors).uniq.sort - ['']
      ages = products.map{|p| p.localized_age}.uniq
      picture_types = products.map{|p| p.picture_type.to_s.mb_chars.downcase.to_s}.compact.uniq - ['']
      orthopedic_properties = products.map{|p| p.orthopedic_properties.map(&:name).join(', ')}.flatten.uniq - ['']

      products_properties = products.map do |product|
        product.product_properties.map do |property|
          {value: property.value, name: property.property.name}
        end
      end.flatten.group_by{|pp| pp[:name]}

      category_names.each do |category_name|
        xml.offer(available: products.on_hand_variants.present?, id: category.id, type: 'vendor.model') do
          xml.url "http://#{@host}/#{category.permalink}#{@utms}"

          xml.price max_price
          xml.currencyId 'RUR'
          xml.categoryId category.id
          xml.name category_name

          brand_names.each_with_index do |brand_name, i|
            xml.param brand_name, name: "brand#{i}"
          end

          colors.each_with_index do |color, i|
            xml.param color, name: "color#{i}"
          end

          ages.each_with_index do |age, i|
            xml.param age, name: "age#{i}"
          end

          picture_types.each_with_index do |picture_type, i|
            xml.param picture_type, name: "picture_type#{i}"
          end

          orthopedic_properties.each_with_index do |orthopedic_property, i|
            xml.param orthopedic_property, name: "orthopedic_property#{i}"
          end

          products_properties.each do |name, values|
            values.map{|v| v[:value]}.uniq.sort.each_with_index do |value, i|
              xml.param value, name: "#{name} #{i}"
            end
          end
        end
      end
    end

    def preferred_category
      Taxon.find_by_name(@config.preferred_category_for_alytics)
    end
  end
end