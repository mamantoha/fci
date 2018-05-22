# frozen_string_literal: true

module FCI
  def build_folder_xml(folder)
    attr = folder.attributes

    folder_xml = Nokogiri::XML::Builder.new do |xml|
      xml.root do
        # id - id of the original folder
        xml.folder(id: folder.id, position: attr[:position], identifier: 'folder', type: 'document') do
          xml.name do
            xml.cdata attr[:name]
          end
          xml.description do
            xml.cdata attr[:description]
          end
        end
      end
    end

    folder_xml
  end

  def build_article_xml(article)
    attr = article.attributes

    article_xml = Nokogiri::XML::Builder.new do |xml|
      xml.root do
        # id - id of the original acticle
        # folder_id - id of the original folder
        xml.article(id: article.id, folder_id: attr[:folder_id], position: attr[:position], identifier: 'article', type: 'document') do
          xml.title do
            xml.cdata attr[:title]
          end
          xml.description do
            xml.cdata attr[:description]
          end
        end
      end
    end

    article_xml
  end

  def build_folder_hash(folder)
    attr = folder.attributes

    {
      id:          folder.id,
      position:    attr[:position],
      name:        attr[:name],
      description: attr[:description]
    }
  end

  def build_article_hash(article)
    attr = article.attributes

    {
      id:          article.id,
      folder_id:   attr[:folder_id],
      position:    attr[:position],
      title:       attr[:title],
      description: attr[:description]
    }
  end
end
