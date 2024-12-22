class ConnectionTest < Minitest::Test
  def setup
    @options = {
      url: "https://salt-master.example.com",
      username: "test_user",
      password: "test_pass",
      eauth: "pam",
      verify_ssl: false,
      timeout: 3,
      retries: 2,
    }

    stub_request(:post, "https://salt-master.example.com/login")
      .with(
        body: { username: "test_user", password: "test_pass", eauth: "pam" }.to_json,
        headers: {
              "Accept" => "application/json",
              "Content-Type" => "application/json",
        }
      )
      .to_return(
        status: 200,
        body: { return: [{ token: "fake_token" }] }.to_json
      )

    @connection = TrainPlugins::Salt::Connection.new(@options)
  end

  # Login tests
  def test_login_success
    assert_equal "fake_token", @connection.token
  end

  def stub_login_failure_request(status, body: {}.to_json)
    stub_request(:post, "https://salt-master.example.com/login")
      .with(
        headers: {
              "Accept" => "application/json",
              "Content-Type" => "application/json",
        }
      )
      .to_return(status: status, body: body)
  end

  def test_login_failure_authentication
    stub_login_failure_request(401)

    assert_raises(TrainPlugins::Salt::AuthenticationError) { @connection = TrainPlugins::Salt::Connection.new(@options) }
  end

  def test_login_failure_badrequest
    stub_login_failure_request(406)

    assert_raises(TrainPlugins::Salt::BadRequest) { @connection = TrainPlugins::Salt::Connection.new(@options) }
  end

  def test_login_failure_internal_error
    stub_login_failure_request(500)

    assert_raises(TrainPlugins::Salt::SaltAPIError) { @connection = TrainPlugins::Salt::Connection.new(@options) }
  end

  def test_run_command_via_connection_sucess
    stub_request(:post, "https://salt-master.example.com/")
      .to_return(
        status: 200,
        body: {
          return: [
            {
              "minion1": {
                "ret": {
                  "pid": 1234,
                  "retcode": 0,
                  "stdout": "hello",
                  "stderr": "world",
                },
                "retcode": 0,
                "jid": "20241222164021154476",
              },
            },
          ],
        }.to_json
      )

    result = @connection.run_command_via_connection("echo Hello")
    assert_equal "hello", result.stdout
    assert_equal "world", result.stderr
    assert_equal 0, result.exit_status
  end

  def test_run_command_via_connection_failure
    stub_request(:post, "https://salt-master.example.com/")
      .to_return(
        status: 200,
        body: {
          return: [
            {
              "minion1": {
                "ret": {
                  "pid": 1234,
                  "retcode": 127,
                  "stdout": "",
                  "stderr": "/bin/sh: 1: abc: not found",
                },
                "retcode": 127,
                "jid": "20241222164021154476",
              },
            },
          ],
        }.to_json
      )

    result = @connection.run_command_via_connection("abc")
    assert_equal "", result.stdout
    assert_equal "/bin/sh: 1: abc: not found", result.stderr
    assert_equal 127, result.exit_status
  end

  # Close session tests
  def stub_close_request(status, body: { return: [{}] }.to_json)
    stub_request(:post, "https://salt-master.example.com/logout")
      .to_return(status: status, body: body)
  end

  def test_close
    stub_close_request(200)

    assert @connection.close
  end

  def test_close_failure_badrequest
    stub_close_request(406)

    assert_raises(TrainPlugins::Salt::BadRequest) { @connection.close }
  end

  def test_close_failure_authentication
    stub_close_request(401)

    assert_raises(TrainPlugins::Salt::AuthenticationError) { @connection.close }
  end

end
