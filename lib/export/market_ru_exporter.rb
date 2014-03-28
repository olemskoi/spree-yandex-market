module Export
  class MarketRuExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=market_ru&utm_medium=market_ru&utm_campaign=market_ru'
    end
  end
end
