module Export
  class NadaviExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=nadavi&utm_medium=nadavi&utm_campaign=nadavi'
    end
  end
end
