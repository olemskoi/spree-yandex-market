module Export
  class SegmentoExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=segmento&utm_medium=segmento&utm_campaign=segmento'
    end
  end
end
