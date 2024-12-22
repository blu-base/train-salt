require "json" unless defined?(JSON)
require "train" unless defined?(Train)

# Connection definition file for an example Train plugin.

# Push platform detection out to a mixin, as it tends
# to develop at a different cadence than the rest
require "train-salt/platform"
require "train-salt/errors"

module TrainPlugins
  module Salt
    class Connection < Train::Plugins::Transport::BaseConnection
      attr_reader :options

      attr_reader :token

      def initialize(options)
        super(options)

        @url = options[:url]

        @host = options[:host]
        @username = options[:username]
        @password = options[:password]
        @eauth = options[:eauth]
        @verify_ssl = options[:verify_ssl]
        @timeout = options[:timeout]
        @retries = options[:retries]
        @token = login
      end

      # Authenticate with the salt-api service and return a session token
      def login
        uri = URI.parse("#{@url}/login")
        http = build_http_client(uri)

        request = Net::HTTP::Post.new(
          uri.path, {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
          }
        )

        request.body = { username: @username, password: @password, eauth: @eauth }.to_json

        response = execute_request(http, request)

        case response
        when Net::HTTPOK
          JSON.parse(response.body)["return"][0]["token"]
        when Net::HTTPUnauthorized
          raise AuthenticationError, "Unauthorized: Incorrect username, password, or eauth."
        when Net::HTTPNotAcceptable
          raise BadRequest, "Requested Content-Type not available"
        when Net::HTTPInternalServerError
          raise SaltAPIError, "Internal Server Error: The salt-api encountered an issue."
        else
          raise BadRequest, "Unexpected response code: #{response.code}"
        end
      end

      def file_via_connection(path, *args)
        if os.aix?
          Train::File::Remote::Aix.new(self, path, *args)
        elsif os.solaris?
          Train::File::Remote::Unix.new(self, path, *args)
        elsif os[:name] == "qnx"
          Train::File::Remote::Qnx.new(self, path, *args)
        elsif os.windows?
          Train::File::Remote::Windows.new(self, path, *args)
        else
          Train::File::Remote::Linux.new(self, path, *args)
        end
      end

      def run_command_via_connection(cmd, opts = {}, &data_handler)
        result = run_function("cmd.run_all", @host, [], { "cmd": cmd })

        stdout = result.values[0]["ret"]["stdout"]
        stderr = result.values[0]["ret"]["stderr"]
        exit_status = result.values[0]["retcode"]

        CommandResult.new(stdout, stderr, exit_status)
      end

      def run_function(function = "test.ping", target = nil, args = [], kwargs = {})
        uri = URI.parse("#{@url}/")
        http = build_http_client(uri)

        request = Net::HTTP::Post.new(
          uri.path,
          {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
            "X-Auth-Token" => @token,
          }
        )

        request.body = {
          client: "local",
          tgt: target,
          fun: function,
          arg: args,
          kwarg: kwargs,
          full_return: true,
        }.to_json

        response = execute_request(http, request)

        case response
        when Net::HTTPOK
          JSON.parse(response.body)["return"][0]
        when Net::HTTPBadRequest
          raise BadRequest, "bad or malformed request"
        when Net::HTTPUnauthorized
          raise AuthenticationError, "Unauthorized: Incorrect username, password, or eauth."
        when Net::HTTPNotAcceptable
          raise BadRequest, "Requested Content-Type not available"
        when Net::HTTPInternalServerError
          raise SaltAPIError, "Internal Server Error: The salt-api encountered an issue."
        else
          raise BadRequest, "Unexpected response code: #{response.code}"
        end
      end

      def close
        uri = URI.parse("#{@url}/logout")
        http = build_http_client(uri)

        request = Net::HTTP::Post.new(
          uri.path,
          {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
            "X-Auth-Token" => @token,
          }
        )

        response = execute_request(http, request)

        case response
        when Net::HTTPOK
          true
        when Net::HTTPUnauthorized
          raise AuthenticationError, "Unauthorized: Incorrect username, password, or eauth."
        when Net::HTTPNotAcceptable
          raise BadRequest, "Requested Content-Type not available."
        else
          raise SaltAPIError, "Unkown return type."
        end
      end

      private def build_http_client(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @ssl_verify
        http.open_timeout = @timeout
        http.read_timeout = @timeout
        http
      end

      private def execute_request(http, request)
        retries_left = @retries

        begin
          http.request(request)
        rescue StandardError => e
          retries_left -= 1
          retry if retries_left > 0
          raise SaltAPIError, "Request failed after #{@retries}: #{e.message}"
        end
      end
    end
  end
end
