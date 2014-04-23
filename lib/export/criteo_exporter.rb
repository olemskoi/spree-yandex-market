module Export
  class CriteoExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=criteo&utm_medium=criteo&utm_campaign=criteo'
    end
  end
end
