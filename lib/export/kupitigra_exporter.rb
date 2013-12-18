module Export
  class KupitigraExporter < AlyticsExporter
    def initialize
      @utms = '?utm_source=kupitigra&utm_medium=kupitigra&utm_campaign=kupitigra'
    end

    protected

    def product_price(product)
      product.variants.where('price > 1.0').map(&:price).min
    end

    def products
      products = Product.in_yandex_market_categories.active.not_gifts.master_price_gte(0.001)
      products.uniq.select { |p| p.yandex_market_category.export_to_yandex_market && p.export_to_yandex_market }
    end

  end
end