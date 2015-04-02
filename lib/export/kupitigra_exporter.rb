module Export
  class KupitigraExporter < AlyticsExporter
    def initialize
      @utms = '?utm_source=kupitigra&utm_medium=kupitigra&utm_campaign=kupitigra'
    end

    protected

    def product_price(product)
      product.variants_including_master.where('price > 1.0').map(&:price).min
    end
  end
end
