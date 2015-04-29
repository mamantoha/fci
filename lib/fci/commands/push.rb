desc 'Read folders/articles from Freshdesk and upload resource files to Crowdin'
command :push do |c|
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

  c.action do |global_options, options, args|
    resources_dir = options[:resources_dir]
    unless File.exists?(resources_dir)
      FileUtils.mkdir(resources_dir)
    end
    resources_config_file = options[:resources_config]

    File.open(resources_config_file, 'a+') do |f|
      config = YAML.load(f)
      unless config # config file empty
        config = {}
        # initialize empty config file
        f.write config.to_yaml
      end
    end

    # for store information about folders/articles ids
    resources_config = YAML.load(File.open(resources_config_file))

    # Source Category
    source_category_id = @fci_config['freshdesk_category'].to_i

    # Check if Category exists in Freshdesk
    source_category = FreshdeskAPI::SolutionCategory.find!(@freshdesk, id: source_category_id)
    raise('No such category') unless source_category.id == source_category_id

    # Get category's folders in Freshdesk
    puts "[Freshdesk] Get folders for Category with id #{source_category_id}"
    folders = @freshdesk.solution_folders(category_id: source_category_id).all!

    folders_builder = []
    folders.each do |folder|
      folder_xml = build_folder_xml(folder)

      # write to resources config file
      unless folder_xml.nil?
        resources_config[:folders] = [] unless resources_config[:folders]
        unless resources_config[:folders].detect { |f| f[:id] == folder.id }
          resources_config[:folders] << { id: folder.id }
        end
      end

      unless folder_xml.nil?
        folders_builder << build_folder_hash(folder).merge({ xml: folder_xml })
      end
    end

    # Get folders articles
    articles_builder = []
    folders.each do |folder|
      puts "[Freshdesk] Get articles for Folder with id #{folder.id}"
      articles = @freshdesk.solution_articles(category_id: source_category_id, folder_id: folder.id).all!

      articles.each do |article|
        article_xml = build_article_xml(article)

        # write to resources config file
        if config_folder = resources_config[:folders].detect { |f| f[:id] == folder.id }
          (config_folder[:articles] ||= []) << { id: article.id }
        else
          abort 'No such folder!'
        end

        unless article_xml.nil?
          articles_builder << build_article_hash(article).merge({ xml:  article_xml })
        end
      end
    end


    crowdin_project_info = @crowdin.project_info

    # Creates xml files for folders and upload to Crowdin
    folders_builder.each do |folder|
      file_name = "folder_#{folder[:id]}.xml"

      o = File.new(File.join(resources_dir, file_name), 'w')
      o.write folder[:xml].to_xml
      o.close

      if crowdin_project_info['files'].detect { |file| file['name'] == file_name }
        puts "[Crowdin] Update file `#{file_name}`"
        @crowdin.update_file(
          files = [
            { source: File.join(resources_dir, file_name), dest: file_name, export_pattert: '/%two_letters_code%/%original_file_name%' }
          ], type: 'webxml'
        )
      else
        puts "[Crowdin] Add file `#{file_name}`"
        @crowdin.add_file(
          files = [
            { source: File.join(resources_dir, file_name), dest: file_name, export_pattert: '/%two_letters_code%/%original_file_name%' }
          ], type: 'webxml'
        )
      end
    end

    # Creates xml files for articles and upload to Crowdin
    articles_builder.each do |article|
      file_name = "article_#{article[:id]}.xml"

      o = File.new(File.join(resources_dir, file_name), 'w')
      o.write article[:xml].to_xml
      o.close

      if crowdin_project_info['files'].detect { |file| file['name'] == file_name }
        puts "[Crowdin] Update file `#{file_name}`"
        @crowdin.update_file(
          files = [
            { source: File.join(resources_dir, file_name), dest: file_name, export_pattert: '/%two_letters_code%/%original_file_name%' }
          ], type: 'webxml'
        )
      else
        puts "[Crowdin] Add file `#{file_name}`"
        @crowdin.add_file(
          files = [
            { source: File.join(resources_dir, file_name), dest: file_name, export_pattert: '/%two_letters_code%/%original_file_name%' }
          ], type: 'webxml'
        )

      end
    end

    # Write resources config file
    puts "Write config file"
    File.open(resources_config_file, 'w') do |f|
      f.write resources_config.to_yaml
    end

  end
end

