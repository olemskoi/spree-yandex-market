module Export
  class AlyticsExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=alytics&utm_medium=alytics&utm_campaign=alytics'
    end

    def preferred_category
      Taxon.find_by_name(@config.preferred_category_for_alytics)
    end

    def product_category_id(product)
      product.cat.id
    end

    def market_category(product)
      product.internal_market_category
    end

    def add_alt_vendor_to_model_name?;false;end
    def add_alt_vendor?;true;end

  end
end