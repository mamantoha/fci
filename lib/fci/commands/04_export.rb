desc 'Add or update localized resource files(folders and articles) in Freshdesk'
command :'export:translations' do |c|
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

    # for store information about folders/articles ids
    unless File.exists?(resources_config_file)
      raise "Error! Config file does not exist. First run `push` command"
    end

    resources_config = YAML.load(File.open(resources_config_file))

    if !resources_config || resources_config.nil? || resources_config.empty?
      raise "Error! Resources config empty. First run `push` command"
    end

    @fci_config['translations'].each do |lang|
      folder_xml_files = Dir["#{resources_dir}/#{lang['crowdin_language_code']}/folder_*.xml"]
      article_xml_files = Dir["#{resources_dir}/#{lang['crowdin_language_code']}/article_*.xml"]

      unless freshdesk_category = FreshdeskAPI::SolutionCategory.find(@freshdesk, id: lang['freshdesk_category_id'].to_i)
        raise "Not such Category ID for language `#{lang['crowdin_language_code']}`in Freshdesk. Please create new one and set ID in config file."
      end

      all_folders = []
      all_articles = []

      # Read folders from XML files
      folder_xml_files.each do |file|
        # Load the xml file into a String
        folder_xml_file = File.read(file)

        folder = parse_folder_xml(folder_xml_file)

        all_folders << folder
      end

      # Read articles from XML filse
      article_xml_files.each do |file|
        article_xml_file = File.read(file)

        article = parse_article_xml(article_xml_file)

        all_articles << article
      end

      ### Folders ###
      #
      all_folders.each do |folder|
        if config_folder = resources_config[:folders].detect { |f| f[:id].to_s == folder[:id].to_s }

          config_folder[:translations] = [] unless config_folder[:translations]

          # if Folder translation ID exists in config
          if folder_translation = config_folder[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }
            # Get folder from Freshdesk and update it
            freshdesk_folder = FreshdeskAPI::SolutionFolder.find(
              @freshdesk,
              category_id: lang['freshdesk_category_id'].to_i,
              id: folder_translation[:id]
            )

            # Remove Folder translation from config it it not found in Freshdesk
            if freshdesk_folder.nil?
              puts "Remove undefined Folder from config"
              config_folder[:translations].delete_if { |tr| tr[:lang] == lang['crowdin_language_code'] }

              puts "[Freshdesk] Create new Folder"
              freshdesk_folder = FreshdeskAPI::SolutionFolder.create!(
                @freshdesk,
                category_id: lang['freshdesk_category_id'].to_i,
                name: folder[:name],
                description: folder[:description],
                visibility: 1
              )

              config_folder[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_folder.id }

            end

            if freshdesk_folder.attributes[:name] != folder[:name] || freshdesk_folder.attributes[:description] != folder[:description]
              puts "[Freshdesk] Update existing Folder"
              freshdesk_folder.update!(name: folder[:name], description: folder[:description])
            else
              puts "[Freshdesk] Nothing to update. An existing Folder still the same."
            end

          else
            # create new folder in Freshdesk and save id to config file
            puts "[Freshdesk] Create new Folder"
            freshdesk_folder = FreshdeskAPI::SolutionFolder.create!(
              @freshdesk,
              category_id: lang['freshdesk_category_id'].to_i,
              name: folder[:name],
              description: folder[:description],
              visibility: 1
            )

            config_folder[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_folder.id }
          end
        else
          abort "No such folder!"
        end
      end # all_folders

      ### Articles ###
      #
      all_articles.each do |article|
        if config_folder = resources_config[:folders].detect { |f| f[:id].to_s == article[:folder_id].to_s }
          unless folder_translation = config_folder[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }
            abort "No `#{lang['crowdin_language_code']}` translations for folder"
          end

          if config_article = config_folder[:articles].detect { |f| f[:id].to_s == article[:id].to_s }
            config_article[:translations] = [] unless config_article[:translations]

            # if Article translation ID exists in config - update article on Freshdesk
            if article_translation = config_article[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }
              freshdesk_article = FreshdeskAPI::SolutionArticle.find(
                @freshdesk,
                category_id: lang['freshdesk_category_id'].to_i,
                folder_id: folder_translation[:id],
                id: article_translation[:id]
              )

              # Remove Article translation from config if it not found in Freshdesk
              if freshdesk_article.nil?
                puts "Remove undefined Article from config"
                config_article[:translations].delete_if { |tr| tr[:lang] == lang['crowdin_language_code'] }

                puts "[Freshdesk] Create new Article"
                freshdesk_article = FreshdeskAPI::SolutionArticle.create!(
                    @freshdesk,
                    category_id: lang['freshdesk_category_id'].to_i,
                    folder_id: folder_translation[:id],
                    title: article[:title],
                    description: article[:description]
                )
                config_article[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_article.id }
                next
              end

              if freshdesk_article.attributes[:title] != article[:title] || freshdesk_article.attributes[:description] != article[:description]
                puts "[Freshdesk] Update existing Article"

                freshdesk_article.update!(
                  title: article[:title],
                  description: article[:description]
                )
              else
                puts "[Freshdesk] Nothing to update. An existing Article still the same."
              end

            else
              # creates new article on Freshdesk and save ID to config file
              if folder_translation = config_folder[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }
                # do nothing for now
              else
                abort "No translation for this folder"
              end

              puts "[Freshdesk] Create new Article"
              freshdesk_article = FreshdeskAPI::SolutionArticle.create!(
                @freshdesk,
                category_id: lang['freshdesk_category_id'].to_i,
                folder_id: folder_translation[:id],
                title: article[:title],
                description: article[:description]
              )
              config_article[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_article.id }
            end
          else
            abort "No such article!"
          end
        else
          abort "No such folder!"
        end
      end # all_articles

      puts "Write info about localization to config"
      File.open(resources_config_file, 'w') do |f|
        f.write resources_config.to_yaml
      end

    end # @fci_config['translations']

  end
end

