require 'active_resource/base'
require 'active_resource/connection'
require 'gdata/http/response'

# Monkey Patching GData::HTTP::Response to respond to .code.
module GData
  module HTTP
    class Response
      alias code status_code
    end
  end
end

module ActiveResource
  class Connection
    private
      # Makes a request to the remote service.
      def request(method, path, *arguments)
        authorize unless @connection
        
        result = ActiveSupport::Notifications.instrument("request.active_resource") do |payload|
          payload[:method]      = method
          payload[:request_uri] = "#{site.scheme}://#{site.host}:#{site.port}#{path}"
          case method
          when :put, :post
            payload[:body]        = arguments[0]
            puts "URL: #{site.scheme}://#{site.host}:#{site.port}#{path}"
            puts arguments[0]
            payload[:result]      = @connection.send(method, "#{site.scheme}://#{site.host}:#{site.port}#{path}", arguments[0])
          else
            payload[:result]      = @connection.send(method, "#{site.scheme}://#{site.host}:#{site.port}#{path}")
          end
        end
        handle_response(result)
      rescue Timeout::Error => e
        raise TimeoutError.new(e.message)
      rescue OpenSSL::SSL::SSLError => e
        raise SSLError.new(e.message)
      end

      def authorize
        @connection = GData::Client::Contacts.new
        @connection.clientlogin(@user, @password)
      end
      
      def with_auth
        retried ||= false
        yield
      rescue UnauthorizedAccess => e
        raise if retried
        authorize
        retried = true
        retry
      end
  end
  
  class Base
    private
      # Only needed for json to not bail out on namespaced elements
      alias orig_find_or_create_resource_for find_or_create_resource_for
      def find_or_create_resource_for(name)
        orig_find_or_create_resource_for(name.to_s.gsub('$', '_'))
      end
  end
end

module ActiveGoogle
  class Resource < ActiveResource::Base
    self.site = "https://www.google.com/m8/feeds/contacts/default/"

    class << self
      def element_path(id, prefix_options = {}, query_options = nil)
        query_options = {}.merge(query_options)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}base/#{URI.escape id.to_s}#{query_string(query_options)}"
      end

      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}full#{query_string(query_options)}"
      end
    end
    
    def id
      attributes[:id].gsub(%r%.*/base/%, '')
    end
  end
end
