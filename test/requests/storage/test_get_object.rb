require File.expand_path '../../test_helper', __dir__

# Storage Blob Class
class TestGetObject < Minitest::Test
  # This class posesses the test cases for the requests of getting storage blob.
  def setup
    Fog.mock!
    @mock_service = Fog::AzureRM::Storage.new(storage_account_credentials)
    Fog.unmock!
    @mocked_response = mocked_storage_http_error

    @service = Fog::AzureRM::Storage.new(storage_account_credentials)
    @blob_client = @service.instance_variable_get(:@blob_client)

    @raw_cloud_blob = storage_blob
    @blob = ApiStub::Requests::Storage::File.blob_as_hash
    @blob_with_content = @blob.merge(body: 'content')
  end

  def test_get_object_success
    @blob_client.stub :get_blob, @blob_with_content do
      assert_equal @blob_with_content, @service.get_object('test_container', 'test_blob')
    end
  end

  def test_get_object_not_found
    exception = ->(*) { raise StandardError.new('Not found(404). Not exist') }
    @blob_client.stub :get_blob, exception do
      assert_raises('NotFound') do
        @service.get_object('test_container', 'test_blob')
      end
    end
  end
end
