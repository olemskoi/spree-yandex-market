module Export
  class KupitigraExporter < AlyticsExporter
    def initialize
      @utms = '?utm_source=kupitigra&utm_medium=kupitigra&utm_campaign=kupitigra'
    end

    protected

    def product_price(product)
      product.variants_including_master.where('price > 1.0').map(&:price).min
    end

    def products
      products = Product.in_yandex_market_categories.active.not_gifts.master_price_gte(0.001)
      products.uniq.select { |p| p.yandex_market_category.export_to_yandex_market && p.export_to_yandex_market }
    end

    def model_name(product)
      model = []
      model << product.brand.name if product.brand
      if product.brand && product.brand.alt_displayed_name.present?
        model << "(#{product.brand.alt_displayed_name})"
      end
      model << product.name
      model.join(' ')
    end

  end
end