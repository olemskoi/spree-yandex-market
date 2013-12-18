module Export
  class MixmarketExporter < KupitigraExporter
    def initialize
      @utms = '?utm_source=mixmarket&utm_medium=mixmarket&utm_campaign=mixmarket'
    end
  end
end