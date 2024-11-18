require File.expand_path '../../test_helper', __dir__

# Storage Blob Class
class TestPutBlobHttpsUrl < Minitest::Test
  # This class posesses the test cases for the requests of Blob service.
  def setup
    Fog.mock!
    @mock_service = Fog::AzureRM::Storage.new(storage_account_credentials)
    Fog.unmock!

    @service = Fog::AzureRM::Storage.new(storage_account_credentials)
    @signature_client = @service.send(:signature_client, Minitest::Mock.new)

    @url = ApiStub::Requests::Storage::File.blob_https_url
    @token = ApiStub::Requests::Storage::File.blob_url_token
  end

  def test_put_blob_https_urls_success
    @signature_client.stub :generate_service_sas_token, @token do
      assert_equal "#{@url}?#{@token}", @service.put_blob_https_url('test_container', 'test_blob', Time.now.utc + 3600)
      assert_equal "#{@url}?#{@token}", @service.put_object_url('test_container', 'test_blob', Time.now.utc + 3600, {})
    end
  end

  def test_put_blob_https_url_mock
    assert_equal "#{@url}?#{@token}", @mock_service.put_blob_https_url('test_container', 'test_blob', Time.now.utc + 3600)
    assert_equal "#{@url}?#{@token}", @mock_service.put_object_url('test_container', 'test_blob', Time.now.utc + 3600, {})
  end
end
