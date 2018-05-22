# frozen_string_literal: true

desc 'Build and download translation resources from Crowdin'
command :'download:translations' do |c|
  c.desc 'Directory of resource files'
  c.long_desc <<-EOS.strip_heredoc
    This is the directory where the project's files will be store.
  EOS
  c.default_value 'resources'
  c.arg_name 'dir'
  c.flag [:resources_dir]

  c.desc 'Resources config file'
  c.long_desc <<-EOS.strip_heredoc
    This is the config file where the information about project's files will be store.
  EOS
  c.default_value 'resources/.resources.yml'
  c.arg_name 'file'
  c.flag [:resources_config]

  c.action do |global_options, options, _args|
    resources_dir = File.join(File.dirname(global_options[:config]), options[:resources_dir])

    language = 'all'
    tempfile = Tempfile.new(language)
    zipfile_name = tempfile.path

    begin
      export_translations!(@crowdin)

      puts 'Downloading translations'
      @crowdin.download_translation(language, output: zipfile_name)

      unzip_file_with_translations(zipfile_name, resources_dir)
    ensure
      tempfile.close
      tempfile.unlink # delete the tempfile
    end
  end
end
