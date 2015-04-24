# fci

Describe your project here

## Configuration

Download example config:

```
curl https://raw.githubusercontent.com/mamantoha/fci/master/fci.yml.example
```

Copy and rename `fci.yaml.example` file to `fci.yml`:

```
---
crowdin_project_id: '<%your-crowdin-project-id%>'
crowdin_api_key: '<%your-crowdin-api-key%>'
crowdin_base_url: 'https://api.crowdin.com'

freshdesk_base_url: 'https://<%subdomain%>.freshdesk.com'
freshdesk_username: '<%your-freshdek-username%>'
freshdesk_password: = '<%your-freshdesk-password%>'

freshdesk_category: '<%category-id%>'

translations:
  -
    crowdin_language_code: '<%crowdin-two-letters-code%>'
    freshdesk_category_id: '<%freshdesk-category-id%>'
  -
    crowdin_language_code: '<%crowdin-two-letters-code%>'
    freshdesk_category_id: '<%freshdesk-category-id%>'

```
