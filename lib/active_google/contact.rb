module ActiveGoogle
  class Contact < Base
    def self.base_url
      "https://www.google.com/m8/feeds/contacts/default/"
    end
    
    def self.collection_url
      base_url + "full"
    end

    attr_accessor :record

    # Contact attributes
    def title
      record.elements['title'].text
    end
    alias name title
    
    def content
      record.elements['content'].text
    end
    alias comments content
    
    def email
      record.elements['gd:email/@address'].value
    end

    def phone_number
      phone_numbers.first
    end

    def phone_numbers
      result = {}
      record.elements.each('gd:phoneNumber') do |e|
        key = e.attribute('rel').value.gsub('http://schemas.google.com/g/2005#', '')
        value = e.text
        
        result[key] = value
      end

      result
    end

    def postal_address
      record.elements['gd:postalAddress'].text
    end
  end
end
