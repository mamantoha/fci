module FCI
  def parse_folder_xml(folder_xml_file)
    doc = Nokogiri::XML.parse(folder_xml_file)
    folder_xml = doc.xpath("//folder").first

    folder = {
      id: folder_xml[:id],
      name: folder_xml.xpath('name').text,
      description: folder_xml.xpath('name').text,
      position: folder_xml[:position],
    }

    return folder
  end

  def parse_article_xml(article_xml_file)
    doc = Nokogiri::XML.parse(article_xml_file)
    article_xml = doc.xpath('//article').first

    article = {
      id: article_xml[:id],
      position: article_xml[:position],
      folder_id: article_xml[:folder_id],
      title: article_xml.xpath('title').text,
      description: article_xml.xpath('description').text,
    }

    return article
  end

end
