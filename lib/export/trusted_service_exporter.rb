module Export
  class TrustedServiceExporter < KupitigraExporter

    def initialize
      @utms = '?utm_source=ts&utm_medium=ts&utm_campaign=ts'
    end

  end
end