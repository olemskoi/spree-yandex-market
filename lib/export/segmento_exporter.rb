module Export
  class SegmentoExporter < YandexMarketExporter

    def initialize
      @utms = '?utm_source=segmento&utm_medium=segmento&utm_campaign=segmento'
    end

    def additional_params_for_offer(xml, product, variant)
      xml.old_price variant.old_price if variant && variant.old_price.to_i > 0
    end

  end
end
