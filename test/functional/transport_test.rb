class TransportTest < Minitest::Test
  def setup
    @options = {
      url: "https://salt-master.example.com",
      username: "test_user",
      password: "test_pass",
      eauth: "pam",
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

    @transport = TrainPlugins::Salt::Transport.new(@options)
  end

  def test_connection
    connection = @transport.connection
    assert_instance_of TrainPlugins::Salt::Connection, connection
  end
end

