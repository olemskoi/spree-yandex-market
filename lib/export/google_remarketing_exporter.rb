module Export
  class GoogleRemarketingExporter < GoogleExporter

    protected

    def utms
      '?utm_source=google-remarketing&utm_medium=google-remarketing&utm_campaign=google-remarketing'
    end
  end
end
