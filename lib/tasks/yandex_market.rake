# -*- coding: utf-8 -*-
namespace :spree_yandex_market do
  desc "Copies public assets of the Yandex Market to the instance public/ directory."
  task :update => :environment do
    is_svn_git_or_dir = proc { |path| path =~ /\.svn/ || path =~ /\.git/ || File.directory?(path) }
    Dir[YandexMarketExtension.root + "/public/**/*"].reject(&is_svn_git_or_dir).each do |file|
      path      = file.sub(YandexMarketExtension.root, '')
      directory = File.dirname(path)
      puts "Copying #{path}..."
      mkdir_p Rails.root + directory
      cp file, Rails.root + path
    end
  end

  desc "Generate Yandex.Market export file"
  task :generate_ym => :environment do
    generate_export_file
  end

  %w(alytics torg_mail_ru olx kupitigra wikimart mail_ru lookmart retail_rocket google
    price_ru mixmarket tradego trusted_service market_ru admitad criteo segmento).each do |export_name|
    desc "Generate #{export_name.titleize} export file"
    task "generate_#{export_name}" => :environment do
      generate_export_file export_name
    end
  end

  def generate_export_file(ts='yandex_market')
    require File.expand_path(File.join(Rails.root, "config/environment"))
    require File.join(File.dirname(__FILE__), '..', "export/#{ts}_exporter.rb")
    
    directory = File.join(Rails.root+"../../current/", 'public', "#{ts}")
    mkdir_p directory unless File.exist?(directory)
    
    ::Time::DATE_FORMATS[:ym] = "%Y-%m-%d %H:%M"
    
    yml_xml = Export.const_get("#{ts.camelize}Exporter").new.export
    
    puts 'Saving file...'

    # Создаем файл, сохраняем в нужной папке,
    tfile_basename = "#{ts}_#{Time.now.strftime("%Y_%m_%d__%H_%M")}"
    tfile = File.new(File.join(directory, tfile_basename), "w+")
    tfile.write(yml_xml)
    tfile.close

    puts 'Creating symlink...'
    
    # Делаем симлинк на ссылку файла yandex_market_last.gz
    `ln -sf "#{tfile.path}" "#{File.join(File.join(Rails.root+"../../current/", 'public', "#{ts}"), "#{ts}.xml")}"`

    # Удаляем лишнии файлы
    @config = Spree::YandexMarket::Config.instance
    @number_of_files = @config.preferred_number_of_files

    @export_files = Dir[File.join(directory, '**', '*')]\
                    .map { |x| [File.basename(x), File.mtime(x)] }\
                    .sort { |x, y| y.last <=> x.last }
    
    e = @export_files.find { |x| x.first == "#{ts}.gz" }
    @export_files.reject! { |x| x.first == "#{ts}.gz" }
    @export_files.unshift(e)

    @export_files[@number_of_files..-1] && @export_files[@number_of_files..-1].each do |x|
      f = File.join(directory, x.first)
      if File.exist?(f)
        Rails.logger.info "[ #{ts} ] удаляем устаревший файл #{f}"
        File.delete(File.join(directory, x.first))
      end
    end
  end
end
