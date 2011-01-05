require 'active_resource/connection'
require 'gdata/http/response'

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
        
        puts "#{site.scheme}://#{site.host}:#{site.port}#{path}"
        result = ActiveSupport::Notifications.instrument("request.active_resource") do |payload|
          payload[:method]      = method
          payload[:request_uri] = "#{site.scheme}://#{site.host}:#{site.port}#{path}"
          payload[:result]      = @connection.send(method, "#{site.scheme}://#{site.host}:#{site.port}#{path}")
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
end

module ActiveGoogle
  class Resource < ActiveResource::Base
    self.site = "https://www.google.com/m8/feeds/contacts/default/"
    self.user = ""
    self.password = ""

    class << self
      def element_path(id, prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}base/#{URI.escape id.to_s}#{query_string(query_options)}"
      end

      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}full#{query_string(query_options)}"
      end
    end
  end
end
