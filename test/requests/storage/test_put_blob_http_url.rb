require File.expand_path '../../test_helper', __dir__

# Storage Blob Class
class TestPutBlobHttpUrl < Minitest::Test
  # This class posesses the test cases for the requests of Blob service.
  def setup
    Fog.mock!
    @mock_service = Fog::AzureRM::Storage.new(storage_account_credentials)
    Fog.unmock!

    @service = Fog::AzureRM::Storage.new(storage_account_credentials)
    @signature_client = @service.send(:signature_client, Minitest::Mock.new)

    @url = ApiStub::Requests::Storage::File.blob_https_url.gsub('https:', 'http:')
    @token = ApiStub::Requests::Storage::File.blob_url_token
  end

  def test_put_blob_http_urls_success
    @signature_client.stub :generate_service_sas_token, @token do
      assert_equal "#{@url}?#{@token}", @service.put_blob_http_url('test_container', 'test_blob', Time.now.utc + 3600)
    end
  end

  def test_put_url_https_in_container_and_blob_names
    uri = URI.parse(@service.put_blob_http_url('https://container', 'https://blob', Time.now.utc + 3600))
    assert_equal 'http', uri.scheme
    assert_equal '/https://container/https://blob', CGI.unescape(uri.path)
  end

  def test_put_blob_http_url_mock
    assert_equal "#{@url}?#{@token}", @mock_service.put_blob_http_url('test_container', 'test_blob', Time.now.utc + 3600)
  end
end
