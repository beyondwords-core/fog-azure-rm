require File.expand_path '../../test_helper', __dir__

require 'webrick'

class TestGetBlobGzipped < Minitest::Test
  def setup
    @server = WEBrick::HTTPServer.new(
      BindAddress: '127.0.0.1',
      Port: 0,
      Logger: WEBrick::Log.new(nil, 0),
      AccessLog: []
    )
    @server_uri = URI.parse("http://#{@server.config.values_at(:BindAddress, :Port).join(':')}/test")
    @thread = Thread.new do
      @server.start
    end

    @service = Fog::AzureRM::Storage.new(storage_account_credentials)
    @blob_client = @service.instance_variable_get(:@blob_client)
  end

  def teardown
    @server&.shutdown
    @thread&.join
  end

  def test_get_blob_with_encoding
    io = StringIO.new.binmode
    gzip = Zlib::GzipWriter.new(io)
    gzip.write "Hello world.\n"
    gzip.close

    @server.mount_proc '/' do |_request, response|
      response.header['Content-Encoding'] = 'gzip'
      response.body = io.string
    end

    blob, content = @blob_client.stub :generate_uri, @server_uri do
      @service.get_blob('test_container', 'test_blob')
    end

    assert_equal 'gzip', blob.properties[:content_encoding]
    assert_equal io.string, content
  end
end
