module ThreeScale
  module Request

    def build_params parameters
      parameters.reject! {|k,v| v.nil? || v.empty?}
      query = parameters.inject([]) do |query, key_value|
        key_value[1] = key_value[1].strip
        query << key_value.join("=")
      end
      query.join("&")
    end

    def get path, params = { }
      process_request :get, path, params
    end

    def delete path, params = { }
      process_request :delete, path, params
    end

    def put path, params = { }
      process_request :put, path, params
    end

    def post path, params = { }
      process_request :post, path, params
    end

    private

    def process_request method, path, params = { }
      #All 3scale requests require the provider_key to authenticate
      params.merge!(:provider_key => ThreeScale.provider_key)

      http_methods = %w(put get post delete)
      h = Net::HTTP.new(ThreeScale.host)
      params = build_params(params)
      if http_methods.include? method.to_s
        if method == :post || method == :put
          http_resp = h.send(method, path, params)
        else
          path = [path,params].join("?")
          http_resp = h.send(method,path)
          http_resp
        end
      else
        raise "Invalid HTTP method call: #{method}"
        false
      end

      case http_resp
      when Net::HTTPSuccess
        build_success_response(http_resp.body)
      when Net::HTTPClientError
        build_error_response(http_resp.body)
      else
        raise Error.new(http_resp)
      end
    end

    def build_success_response(body)
      response = Response.new(body,:success => true)
    end

    def build_error_response(body)
      response = Response.new(body,:success => false)
      doc = Nokogiri::XML(body)
      node = doc.at_css('error')
      unless node.blank?
        response.add_error(node.content.to_s.strip, node['code'].to_s.strip)
      end
      response
    end

    class Response
      def initialize(body,options)
        @body = Crack::XML.parse(body)
        @success = options[:success]
        @errors  = []
        @metrics = []
      end

      attr_reader  :errors, :metrics,:body

      def success?
        @success
      end

      Error = Struct.new(:message,:code)

      def add_error(*args)
        @errors << Error.new(*args)
      end

      def add_metric(*args)
        @metrics << Metric.new(*args)
      end

    end

  end
end



