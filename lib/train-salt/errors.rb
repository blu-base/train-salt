module TrainPlugins
  module Salt
    class AuthenticationError < StandardError; end
    class TimeoutError < StandardError; end
    class SaltAPIError < StandardError; end
    class BadRequest < StandardError; end
    class BadResponse < StandardError; end
  end
end
