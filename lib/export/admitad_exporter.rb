module Export
  class AdmitadExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=admitad&utm_medium=admitad&utm_campaign=admitad'
    end
  end
end
