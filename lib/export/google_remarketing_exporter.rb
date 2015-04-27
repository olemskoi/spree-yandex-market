module Export
  class GoogleRemarketingExporter < GoogleExporter

    protected

    def utms
      '?utm_source=google-remarketing&utm_medium=remarketing&utm_campaign=remarketing'
    end
  end
end
