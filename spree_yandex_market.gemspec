# -*- encoding: utf-8 -*-
# stub: spree_yandex_market 1.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "spree_yandex_market"
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.date = "2014-06-18"
  s.files = [".gitignore", "LICENSE", "README.markdown", "Rakefile", "app/controllers/admin/taxons_controller_decorator.rb", "app/controllers/admin/yandex_market_settings_controller.rb", "app/helpers/admin/yandex_markets_helper.rb", "app/models/yandex_market_configuration.rb", "app/overrides/yandex_market_admin_tabs.rb", "app/views/admin/yandex_market_settings/currency.html.erb", "app/views/admin/yandex_market_settings/export_files.html.erb", "app/views/admin/yandex_market_settings/general.html.erb", "app/views/admin/yandex_market_settings/shared/_configuration_menu.html.erb", "app/views/admin/yandex_market_settings/show.html.erb", "app/views/admin/yandex_market_settings/ware_property.html.erb", "config/locales/en-US.yml", "config/locales/ru.yml", "config/routes.rb", "db/migrate/20110110094042_add_export_flag_to_product.rb", "db/migrate/20120424050308_add_export_flag_to_taxon.rb", "lib/export/activizm_exporter.rb" "lib/export/admitad_exporter.rb", "lib/export/alytics_exporter.rb", "lib/export/berito_exporter.rb", "lib/export/criteo_exporter.rb", "lib/export/google_exporter.rb", "lib/export/kupitigra_exporter.rb", "lib/export/lookmart_exporter.rb", "lib/export/mail_ru_exporter.rb", "lib/export/market_ru_exporter.rb", "lib/export/mixmarket_exporter.rb", "lib/export/olx_exporter.rb", "lib/export/price_ru_exporter.rb", "lib/export/retail_rocket_exporter.rb", "lib/export/segmento_exporter.rb", "lib/export/torg_mail_ru_exporter.rb", "lib/export/tradego_exporter.rb", "lib/export/trusted_service_exporter.rb", "lib/export/wikimart_exporter.rb", "lib/export/yandex_market_exporter.rb", "lib/generators/spree_yandex_market/install_generator.rb", "lib/spree/yandex_market/config.rb", "lib/spree_yandex_market.rb", "lib/spree_yandex_market_hooks.rb", "lib/tasks/yandex_market.rake", "spec/controllers/admin/yandex_markets_controller_spec.rb", "spec/controllers/yandex_market_controller_spec.rb", "spec/helpers/admin/yandex_markets_helper_spec.rb", "spec/helpers/yandex_market_helper_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "spree_yandex_market.gemspec"]
  s.homepage = "https://github.com/romul/spree-yandex-market"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.requirements = ["none"]
  s.rubygems_version = "2.1.10"
  s.summary = "Export products to Yandex.Market"
  s.test_files = ["spec/controllers/admin/yandex_markets_controller_spec.rb", "spec/controllers/yandex_market_controller_spec.rb", "spec/helpers/admin/yandex_markets_helper_spec.rb", "spec/helpers/yandex_market_helper_spec.rb", "spec/spec.opts", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<spree_core>, ["~> 0.70.0"])
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.5"])
    else
      s.add_dependency(%q<spree_core>, ["~> 0.70.0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.5"])
    end
  else
    s.add_dependency(%q<spree_core>, ["~> 0.70.0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.5"])
  end
end
