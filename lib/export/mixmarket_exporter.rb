module Export
  class MixmarketExporter < KupitigraExporter
    def initialize
      @utms = '?utm_source=mixmarket&utm_medium=mixmarket&utm_campaign=mixmarket'
    end

    protected

    def offer_vendor_model(xml, product)
      return unless product_price(product).present? && product_category_id(product).present?

      xml.offer(id: product.id) do
        xml.url "http://#{@host}/id/#{product.id}#{@utms}"
        xml.price product_price(product)
        xml.currencyId currency_id
        xml.categoryId product_category_id(product)
        xml.picture image_url(product.images.first) if product.images.first.present?
        xml.name model_name(product)
        xml.description product_description(product) if product_description(product)
      end
    end
  end
end