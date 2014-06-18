module Export
  class BeritoExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=berito&utm_medium=berito&utm_campaign=berito'
    end
  end
end
