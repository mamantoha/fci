# FCI

Freshdesk and Crowdin integration Command Line Interface (CLI)

## Installation

Add this line to your application's Gemfile:

```
gem 'fci'
```

And then execute:
```
$ bundle
```

Or install it manually as:

```
$ gem install fci
```

## Use

The simplest way to get started is to create a scaffold project:

```
> fci init todo
```

A new ./todo directory is created with sample config `fci.yml`. View the basic output of the scaffold with:

```
> cd todo
> fci help
```

Which will output:

```
NAME
    fci - is a command line tool that allows you to manage and synchronize your Freshdesk localization with Crowdin project

SYNOPSIS
    fci [global options] command [command options] [arguments...]

VERSION
    0.0.1

GLOBAL OPTIONS
    -c, --config=<s> - Project-specific configuration file (default: /home/user/project/fci.yml)
    --version        - Display the program version
    -v, --verbose    - Be verbose
    --help           - Show this message

COMMANDS
    help                  - Shows a list of commands or help for particular command
    init:project          - Create a new FCI-based project
    import:sources        - Read folders/articles from Freshdesk and upload resource files to Crowdin
    download:translations - Build and download translation resources from Crowdin
    export:translations   - Add or update localized resource files(folders and articles) in Freshdesk
```

## Configuration

The scaffold project that was created in ./todo comes with a `fci.yml` shell.

```
---
# Crowdin API credentials
crowdin_project_id: '<%your-crowdin-project-id%>'
crowdin_api_key: '<%your-crowdin-api-key%>'
crowdin_base_url: 'https://api.crowdin.com'

# Freshdesk API credentials
freshdesk_base_url: 'https://<%subdomain%>.freshdesk.com'
freshdesk_username: '<%your-freshdek-username%>'
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
```

## Supported Rubies

Tested with the following Ruby versions:

- MRI 2.2.0
- JRuby 9.0.0.0.pre2

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License and Author

Author: Anton Maminov (anton.maminov@gmail.com)

Copyright: 2015 [crowdin.com](http://crowdin.com/)

This project is licensed under the MIT license, a copy of which can be found in the LICENSE file.
