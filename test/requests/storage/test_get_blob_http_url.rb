require File.expand_path '../../test_helper', __dir__

# Storage Blob Class
class TestGetBlobHttpUrl < Minitest::Test
  # This class posesses the test cases for the requests of Blob service.
  def setup
    Fog.mock!
    @mock_service = Fog::AzureRM::Storage.new(storage_account_credentials)
    Fog.unmock!

    @service = Fog::AzureRM::Storage.new(storage_account_credentials)
    @blob_client = @service.instance_variable_get(:@blob_client)
    @signature_client = @service.send(:signature_client, Minitest::Mock.new)

    @url = ApiStub::Requests::Storage::File.blob_https_url.gsub('https:', 'http:')
    @token = ApiStub::Requests::Storage::File.blob_url_token
  end

  def test_get_blob_http_url_success
    @signature_client.stub :generate_service_sas_token, @token do
      assert_equal "#{@url}?#{@token}", @service.get_blob_http_url('test_container', 'test_blob', Time.now.utc + 3600)
    end
  end

  def test_get_blob_http_url_with_content_disposition
    mock_generate_uri = Minitest::Mock.new
    mock_generate_service_token = Minitest::Mock.new
    url_params = { content_disposition: 'attachment' }

    mock_generate_uri.expect(:call, URI.parse(@url), ['test_container/test_blob', {}, { encode: true }])
    mock_generate_service_token.expect(:call, @token) do |_relative_path, params|
      params[:service] == 'b' &&
        params[:resource] == 'b' &&
        params[:permissions] == 'r' &&
        params[:protocol].nil? &&
        params[:content_disposition] == url_params[:content_disposition]
    end

    @blob_client.stub :generate_uri, mock_generate_uri do
      @signature_client.stub :generate_service_sas_token, mock_generate_service_token do
        assert_equal "#{@url}?#{@token}", @service.get_blob_http_url('test_container', 'test_blob', Time.now.utc + 3600, url_params)
      end
    end
  end

  def test_get_url_remove_trailing_periods_from_path_segments
    mock_generate_uri = Minitest::Mock.new
    mock_generate_service_token = Minitest::Mock.new

    mock_generate_uri.expect(:call, URI.parse(@url), ['.test0/..test1/...test2', {}, { encode: true }])
    mock_generate_service_token.expect(:call, @token) do |relative_path, _|
      relative_path == '.test0/..test1/...test2'
    end

    @blob_client.stub :generate_uri, mock_generate_uri do
      @signature_client.stub :generate_service_sas_token, mock_generate_service_token do
        assert_equal "#{@url}?#{@token}", @service.get_blob_http_url('.test0.', '..test1../...test2...', Time.now.utc + 3600)
      end
    end
  end

  def test_get_url_https_in_container_and_blob_names
    uri = URI.parse(@service.get_blob_http_url('https://container', 'https://blob', Time.now.utc + 3600))
    assert_equal 'http', uri.scheme
    assert_equal '/https://container/https://blob', CGI.unescape(uri.path)
  end

  def test_get_blob_http_url_mock
    assert_equal "#{@url}?#{@token}", @mock_service.get_blob_http_url('test_container', 'test_blob', Time.now.utc + 3600)
  end
end
