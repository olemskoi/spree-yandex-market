module Export
  class PriceRuExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=price_ru&utm_medium=price_ru&utm_campaign=price_ru'
    end

  end
end
