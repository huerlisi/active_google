module ActiveGoogle
  class Base
    # Connection
    def self.establish_connection(spec = {})
      @@connection = GData::Client::Calendar.new
      if user = spec[:user] and password = spec[:password]
        @@connection.clientlogin(spec[:user], spec[:password])
      else
        raise "establish_connections needs :user and :password parameters"
      end
      
      true
    end
    
    def self.connection
      @@connection
    end

    # Collection
    def self.get_collection(params = "")
      connection.get(collection_url + '?prettyprint=true' + params).to_xml
    end
    
    def self.get_record(id, params = "")
      id = id.to_s
      query = base_url + 'base/' + id + '?prettyprint=true' + params
      puts query
      connection.get(query).to_xml
    end
    
    def self.count
      get_collection('max-results=0').elements['openSearch:totalResults'].text.to_i
    end
    
    def self.first
      record = self.new
      record.record =  get_collection('max-results=1').elements['entry']
      
      return record
    end

    def self.find(id)
      record = self.new
      record.record =  get_record(id)
      
      return record
    end
  end
end
