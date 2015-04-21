module Export
  class TechnoportalExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=technoportal&utm_medium=technoportal&utm_campaign=technoportal'
    end
  end
end
