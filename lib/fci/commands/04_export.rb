# frozen_string_literal: true

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

  c.action do |global_options, options, _args|
    resources_dir = File.join(File.dirname(global_options[:config]), options[:resources_dir])
    resources_config_file = File.join(File.dirname(global_options[:config]), options[:resources_config])

    # for store information about folders/articles ids
    unless File.exist?(resources_config_file)
      raise 'Error! Config file does not exist. First run `import:sources` command.'
    end

    resources_config = YAML.safe_load(File.open(resources_config_file))

    if !resources_config || resources_config.nil? || resources_config.empty?
      raise 'Error! Resources config empty. First run `push` command.'
    end

    @cli_config['categories'].each do |category|
      category['translations'].each do |lang|
        freshdesk_category = FreshdeskAPI::SolutionCategory.find(@freshdesk, id: lang['freshdesk_category_id'].to_i)
        unless freshdesk_category
          puts "[WARNING] Not such Category\##{lang['freshdesk_category_id']} for language `#{lang['crowdin_language_code']}` in Freshdesk. Please create new one and set `:freshdesk_category_id` in config file."
          next
        end

        folder_xml_files = Dir["#{resources_dir}/#{lang['crowdin_language_code']}/#{category['freshdesk_category']}/folder_*.xml"]
        article_xml_files = Dir["#{resources_dir}/#{lang['crowdin_language_code']}/#{category['freshdesk_category']}/article_*.xml"]

        if folder_xml_files.empty? && article_xml_files.empty?
          puts "[WARNING] There are no translations for language `#{lang['crowdin_language_code']}`. First run `download:translations` command."
          next
        end

        all_folders = []
        all_articles = []

        # Read folders from XML files
        folder_xml_files.each do |file|
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
          category_config = resources_config[category['freshdesk_category'].to_i]

          folder_config = category_config[:folders].detect { |f| f[:id].to_s == folder[:id].to_s }
          if folder_config
            folder_config[:translations] = [] unless folder_config[:translations]

            # if Folder translation ID exists in config
            folder_translation = folder_config[:translations].detect { |tr| tr[:lang] == lang['crowdin_language_code'] }
            if folder_translation
              # Get folder from Freshdesk and update it
              freshdesk_folder = FreshdeskAPI::SolutionFolder.find(
                @freshdesk,
                category_id: lang['freshdesk_category_id'].to_i,
                id: folder_translation[:id]
              )

              # Remove Folder translation from config it it not found in Freshdesk
              if freshdesk_folder.nil?
                puts '[INFO] Removing undefined Folder from config.'
                folder_config[:translations].delete_if { |tr| tr[:lang] == lang['crowdin_language_code'] }

                puts "[Freshdesk] Create new Folder `#{folder[:name]}` for language `#{lang['crowdin_language_code']}`."
                freshdesk_folder = FreshdeskAPI::SolutionFolder.create!(
                  @freshdesk,
                  category_id: lang['freshdesk_category_id'].to_i,
                  name: folder[:name],
                  description: folder[:description],
                  visibility: 1
                )

                folder_config[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_folder.id }
              end

              if freshdesk_folder.attributes[:name] != folder[:name] || freshdesk_folder.attributes[:description] != folder[:description]
                puts '[Freshdesk] Update existing Folder.'
                freshdesk_folder.update!(name: folder[:name], description: folder[:description])
              else
                puts "[Freshdesk] Nothing to update. An existing Folder\##{folder[:id]} still the same."
              end
            else
              # create new folder in Freshdesk and save id to config file
              puts "[Freshdesk] Create new Folder `#{folder[:name]}` for language `#{lang['crowdin_language_code']}`."
              freshdesk_folder = FreshdeskAPI::SolutionFolder.create!(
                @freshdesk,
                category_id: lang['freshdesk_category_id'].to_i,
                name: folder[:name],
                description: folder[:description],
                visibility: 1
              )

              folder_config[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_folder.id }
            end
          else
            abort 'No such folder!'
          end
        end

        puts "[INFO] Write info about Folders localization for language `#{lang['crowdin_language_code']}` for Category\##{freshdesk_category.id} to config."
        File.open(resources_config_file, 'w') do |f|
          f.write resources_config.to_yaml
        end

        ### Articles ###
        #
        all_articles.each do |article|
          category_config = resources_config[category['freshdesk_category'].to_i]
          folder_config = category_config[:folders].detect { |f| f[:id].to_s == article[:folder_id].to_s }
          if folder_config
            folder_translation = folder_config[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }
            unless folder_translation
              abort "No `#{lang['crowdin_language_code']}` translations for folder."
            end

            article_config = folder_config[:articles].detect { |f| f[:id].to_s == article[:id].to_s }
            if article_config
              article_config[:translations] = [] unless article_config[:translations]

              # if Article translation ID exists in config - update article on Freshdesk
              article_translation = article_config[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }
              if article_translation
                freshdesk_article = FreshdeskAPI::SolutionArticle.find(
                  @freshdesk,
                  category_id: lang['freshdesk_category_id'].to_i,
                  folder_id: folder_translation[:id],
                  id: article_translation[:id]
                )

                # Remove Article translation from config if it not found in Freshdesk
                if freshdesk_article.nil?
                  puts '[INFO] Removing undefined Article from config.'
                  article_config[:translations].delete_if { |tr| tr[:lang] == lang['crowdin_language_code'] }

                  puts '[Freshdesk] Create new Article.'
                  freshdesk_article = FreshdeskAPI::SolutionArticle.create!(
                    @freshdesk,
                    category_id: lang['freshdesk_category_id'].to_i,
                    folder_id: folder_translation[:id],
                    title: article[:title],
                    description: article[:description],
                    status: 2
                  )
                  article_config[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_article.id }
                  next
                end

                if freshdesk_article.attributes[:title] != article[:title] || freshdesk_article.attributes[:description] != article[:description]
                  puts "[Freshdesk] Update existing Article\##{article[:id]}."

                  freshdesk_article.update!(
                    title: article[:title],
                    description: article[:description]
                  )
                else
                  puts "[Freshdesk] Nothing to update. An existing Article\##{article[:id]} still the same."
                end

              else
                # creates new article on Freshdesk and save ID to config file
                folder_translation = folder_config[:translations].detect { |t| t[:lang] == lang['crowdin_language_code'] }

                abort 'No translation for this folder.' unless folder_translation

                puts '[Freshdesk] Create new Article.'
                freshdesk_article = FreshdeskAPI::SolutionArticle.create!(
                  @freshdesk,
                  category_id: lang['freshdesk_category_id'].to_i,
                  folder_id: folder_translation[:id],
                  title: article[:title],
                  description: article[:description],
                  status: 2
                )
                article_config[:translations] << { lang: lang['crowdin_language_code'], id: freshdesk_article.id }
              end
            else
              abort 'No such article!'
            end
          else
            abort 'No such folder!'
          end
        end

        puts "[INFO] Write info about Articles localization for language `#{lang['crowdin_language_code']}` for Category\##{freshdesk_category.id} to config."
        File.open(resources_config_file, 'w') do |f|
          f.write resources_config.to_yaml
        end
      end
    end
  end
end
