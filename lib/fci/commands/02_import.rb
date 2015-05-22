desc 'Read folders/articles from Freshdesk and upload resource files to Crowdin'
command :'import:sources' do |c|
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
    resources_dir = File.join(File.dirname(global_options[:config]), options[:resources_dir])
    resources_config_file = File.join(File.dirname(global_options[:config]), options[:resources_config])

    unless File.exists?(resources_dir)
      FileUtils.mkdir(resources_dir)
    end

    File.open(resources_config_file, 'a+') do |f|
      config = YAML.load(f)
      unless config # config file empty
        config = {}
        # initialize empty config file
        f.write config.to_yaml
      end
    end

    # for store information about categories/folders/articles ids
    resources_config = YAML.load(File.open(resources_config_file))

    @fci_config['categories'].each do |category|
      # Source Category
      source_category_id = category['freshdesk_category'].to_i

      # Check if Category exists in Freshdesk
      source_category = FreshdeskAPI::SolutionCategory.find!(@freshdesk, id: source_category_id)
      raise('No such category') unless source_category.id == source_category_id

      # Check if Category exists in resources config
      unless resources_config[source_category_id]
        category_config = resources_config.merge!(source_category_id => {})[source_category_id]
      else
        category_config = resources_config[source_category_id]
      end

      # Get category's folders in Freshdesk
      puts "[Freshdesk] Get folders for Category with id #{source_category_id}"
      folders = @freshdesk.solution_folders(category_id: source_category_id).all!

      folders_builder = []
      folders.each do |folder|
        folder_xml = build_folder_xml(folder)

        # write to resources config file
        unless folder_xml.nil?
          category_config[:folders] = [] unless category_config[:folders]
          unless category_config[:folders].detect { |f| f[:id] == folder.id }
            category_config[:folders] << { id: folder.id }
          end
        end

        unless folder_xml.nil?
          folders_builder << build_folder_hash(folder).merge({ xml: folder_xml })
        end
      end

      folders_config = resources_config[source_category_id][:folders]
      # Get articles for each folder
      articles_builder = []
      folders.each do |folder|
        puts "[Freshdesk] Get articles for Folder with id #{folder.id}"
        articles = @freshdesk.solution_articles(category_id: source_category_id, folder_id: folder.id).all!

        articles.each do |article|
          article_xml = build_article_xml(article)

          # write to resources config file
          if config_folder = folders_config.detect { |f| f[:id] == folder.id }
            config_folder[:articles] = [] unless config_folder[:articles]
            unless config_folder[:articles].detect { |a| a[:id] == article.id }
              config_folder[:articles] << { id: article.id }
            end
          else
            abort 'No such folder!'
          end

          unless article_xml.nil?
            articles_builder << build_article_hash(article).merge({ xml:  article_xml })
          end
        end
      end

      crowdin_project_info = @crowdin.project_info
      remote_project_tree = get_remote_files_hierarchy(crowdin_project_info['files'])

      resources_category_dir = File.join(resources_dir, source_category_id.to_s)
      unless File.exists?(resources_category_dir)
        FileUtils.mkdir(resources_category_dir)
      end

      # Create directory for Category on Crowdin if it does not exist yet
      unless remote_project_tree[:dirs].include?("/#{source_category_id}")
        puts "[Crowdin] Create directory `#{source_category_id}`"
        @crowdin.add_directory(source_category_id.to_s)
        @crowdin.change_directory(source_category_id.to_s, title: source_category.attributes[:name])
      end

      # Creates xml files for folders and upload to Crowdin
      folders_builder.each do |folder|
        file_name = "folder_#{folder[:id]}.xml"

        o = File.new(File.join(resources_category_dir, file_name), 'w')
        o.write folder[:xml].to_xml
        o.close

        files = [
          {
            source:         File.join(resources_category_dir, file_name),
            dest:           File.join(source_category_id.to_s, file_name),
            export_pattert: '/%two_letters_code%/%original_path%/%original_file_name%',
            title:          folder[:name]
          }
        ]

        if remote_project_tree[:files].include?("/#{source_category_id}/#{file_name}")
          puts "[Crowdin] Update file `#{file_name}`"
          @crowdin.update_file(files, type: 'webxml')
        else
          puts "[Crowdin] Add file `#{file_name}`"
          @crowdin.add_file(files, type: 'webxml')
        end
      end

      # Creates xml files for articles and upload to Crowdin
      articles_builder.each do |article|
        file_name = "article_#{article[:id]}.xml"

        o = File.new(File.join(resources_category_dir, file_name), 'w')
        o.write article[:xml].to_xml
        o.close

        files = [
          {
            source:         File.join(resources_category_dir, file_name),
            dest:           File.join(source_category_id.to_s, file_name),
            export_pattert: '/%two_letters_code%/%original_path%/%original_file_name%',
            title:          article[:title]
          }
        ]

        if remote_project_tree[:files].include?("/#{source_category_id}/#{file_name}")
          puts "[Crowdin] Update file `#{file_name}`"
          @crowdin.update_file(files, type: 'webxml')
        else
          puts "[Crowdin] Add file `#{file_name}`"
          @crowdin.add_file(files, type: 'webxml')

        end
      end

      # Write resources config file
      puts "Write config file for Category with id `#{source_category_id}`"
      File.open(resources_config_file, 'w') do |f|
        f.write resources_config.to_yaml
      end

    end # @fci_config['categories'].each
  end
end
