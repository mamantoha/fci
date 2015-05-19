module FCI
  def build_folder_xml(folder)
    attr = folder.attributes

    folder_xml = Nokogiri::XML::Builder.new do |xml|
      xml.root {
        # id - id of the original folder
        xml.folder(id: folder.id, position: attr[:position], identifier: 'folder', type: 'document') {
          xml.name {
            xml.cdata attr[:name]
          }
          xml.description {
            xml.cdata attr[:description]
          }
        }
      }
    end

    return folder_xml
  end

  def build_article_xml(article)
    attr = article.attributes

    article_xml = Nokogiri::XML::Builder.new do |xml|
      xml.root {
        # id - id of the original acticle
        # folder_id - id of the original folder
        xml.article(id: article.id, folder_id: attr[:folder_id], position: attr[:position], identifier: 'article', type: 'document') {
          xml.title {
            xml.cdata attr[:title]
          }
          xml.description {
            xml.cdata attr[:description]
          }
        }
      }
    end

    return article_xml
  end

  def build_folder_hash(folder)
    attr = folder.attributes

    return {
      id:          folder.id,
      position:    attr[:position],
      name:        attr[:name],
      description: attr[:description],
    }
  end

  def build_article_hash(article)
    attr = article.attributes

    return {
      id:          article.id,
      folder_id:   attr[:folder_id],
      position:    attr[:position],
      title:       attr[:title],
      description: attr[:description],
    }
  end

end
