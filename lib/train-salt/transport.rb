# Train Plugins v1 are usually declared under the TrainPlugins namespace.
# Each plugin has three components: Transport, Connection, and Platform.
# We'll only define the Transport here, but we'll refer to the others.
require "train-salt/connection"

module TrainPlugins
  module Salt
    class Transport < Train.plugin(1)
      name "salt"

      option :url, required: true, default: nil,
             description: "The base URL of the salt-api service (e.g., https//salt-master.internal:8000)"

      option :verify_ssl, default: true,
             description: "Verify SSL session for HTTP requests"

      option :username, required: true, default: nil,
             description: "Username to authenticate with the salt API"

      option :password, required: true, default: nil, sensitive: true,
             description: "Passwort, or Secret to authenticate with the salt API"

      option :eauth, required: true, default: nil,
             description: "EAauth module to authenticate with the salt API (e.g. pam, ldap, file)"

      option :timeout, default: 60,
             description: "Timeout for Requests to the salt-api. The default is 60 seconds"

      option :retries, default: 3,
             description: "Default retries to the salt-api. The default is 3"


      def connection(_instance_opts = nil)
        @connection ||= TrainPlugins::Salt::Connection.new(@options)
      end
    end
  end
end
