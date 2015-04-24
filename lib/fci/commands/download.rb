desc 'Build and download latest translations from Crowdin'
arg_name 'Describe arguments to init here'
command :download do |c|
  c.action do |global_options, options, args|
    language = 'all'
    tempfile = Tempfile.new(language)
    zipfile_name = tempfile.path

    begin
      export_translations!(@crowdin)

      puts 'Downloading translations'
      @crowdin.download_translation(language, output: zipfile_name)

      base_path = Dir.pwd
      unzip_file_with_translations(zipfile_name, base_path)
    ensure
      tempfile.close
      tempfile.unlink # delete the tempfile
    end

  end
end

