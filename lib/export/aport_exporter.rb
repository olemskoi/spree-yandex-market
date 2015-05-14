module Export
  class AportExporter < YandexMarketExporter
    def initialize
      @utms = '?utm_source=aport&utm_medium=aport&utm_campaign=aport'
    end
  end
end
