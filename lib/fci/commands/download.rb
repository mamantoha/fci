desc 'Build and download last exported translation resources from Crowdin'
command :download do |c|
  c.desc 'Directory of resource files'
  c.long_desc <<-EOS.strip_heredoc
    This is the directory where the project's files will be store.
  EOS
  c.default_value 'resources'
  c.arg_name 'dir'
  c.flag [:resources_dir]

  c.action do |global_options, options, args|
    language = 'all'
    tempfile = Tempfile.new(language)
    zipfile_name = tempfile.path
    resources_dir = options[:resources_dir]

    base_path = File.join(Dir.pwd, resources_dir)
    begin
      export_translations!(@crowdin)

      puts 'Downloading translations'
      @crowdin.download_translation(language, output: zipfile_name)

      base_path = File.join(Dir.pwd, resources_dir)
      unzip_file_with_translations(zipfile_name, base_path)
    ensure
      tempfile.close
      tempfile.unlink # delete the tempfile
    end

  end
end
