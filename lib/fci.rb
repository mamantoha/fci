# frozen_string_literal: true

require 'fci/version.rb'

require 'freshdesk_api'
require 'crowdin-api'
require 'nokogiri'
require 'zip'

# require 'byebug'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file
require 'fci/helpers.rb'
require 'fci/init.rb'
require 'fci/import.rb'
require 'fci/download.rb'
require 'fci/export.rb'
