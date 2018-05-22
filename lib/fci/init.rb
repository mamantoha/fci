# frozen_string_literal: true

require 'fileutils'

module FCI
  def create_scaffold(root_dir, project_name, force)
    dir = File.join(root_dir, project_name)

    mk_config(root_dir, project_name) if mkdir(dir, force)
  end

  def mkdir(dir, force)
    exists = false
    unless force
      raise "#{dir} exists; use --force to override" if File.exist?(dir)
    end

    if !exists
      puts "Creating dir #{dir}..."
      FileUtils.mkdir_p dir
    else
      puts 'Exiting...'
      false
    end

    true
  end

  def mk_config(root_dir, project_name)
    config = <<-EOS.strip_heredoc
    ---
    # Crowdin API credentials
    crowdin_project_id: '<%your-crowdin-project-id%>'
    crowdin_api_key: '<%your-crowdin-api-key%>'
    crowdin_base_url: 'https://api.crowdin.com'

    # Freshdesk API credentials
    freshdesk_base_url: 'https://<%subdomain%>.freshdesk.com'
    freshdesk_username: '<%your-freshdesk-username%>'
    freshdesk_password: '<%your-freshdesk-password%>'

    # Freshdesk catogories
    categories:
    - freshdesk_category: '<%freshdesk-category-id%>'
      translations:
        -
          crowdin_language_code: '<%crowdin-two-letters-code%>'
          freshdesk_category_id: '<%freshdesk-category-id%>'
        -
          crowdin_language_code: '<%crowdin-two-letters-code%>'
          freshdesk_category_id: '<%freshdesk-category-id%>'
    - freshdesk_category: '<%freshdesk-category-id%>'
      translations:
        -
          crowdin_language_code: '<%crowdin-two-letters-code%>'
          freshdesk_category_id: '<%freshdesk-category-id%>'
        -
          crowdin_language_code: '<%crowdin-two-letters-code%>'
          freshdesk_category_id: '<%freshdesk-category-id%>'
    EOS

    File.open("#{root_dir}/#{project_name}/fci.yml", 'w') do |file|
      file << config
    end

    puts "Created #{root_dir}/#{project_name}/fci.yml"
  end
end
