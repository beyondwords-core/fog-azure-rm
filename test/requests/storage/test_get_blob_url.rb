require File.expand_path '../../test_helper', __dir__

# Storage Blob Class
class TestGetBlobUrl < Minitest::Test
  # This class posesses the test cases for the requests of Blob service.
  def setup
    Fog.mock!
    @mock_service = Fog::AzureRM::Storage.new(storage_account_credentials)
    Fog.unmock!
  end

  def test_get_blob_url_success
    service = Fog::AzureRM::Storage.new(storage_account_credentials)
    blob_client = service.instance_variable_get(:@blob_client)

    mock_generate_uri = Minitest::Mock.new
    url = ApiStub::Requests::Storage::File.blob_https_url
    2.times do
      mock_generate_uri.expect(:call, URI.parse(url), ['test_container/test_blob', {}, { encode: true }])
    end

    blob_client.stub :generate_uri, mock_generate_uri do
      assert_equal url, service.get_blob_url('test_container', 'test_blob')

      options = { scheme: 'http' }
      assert_equal url.gsub('https:', 'http:'), service.get_blob_url('test_container', 'test_blob', options)
    end
  end

  def test_get_blob_url_for_china_success
    china_storage_account_credentials = storage_account_credentials.merge(environment: Fog::AzureRM::ENVIRONMENT_AZURE_CHINA_CLOUD)
    service = Fog::AzureRM::Storage.new(china_storage_account_credentials)
    url = ApiStub::Requests::Storage::File.blob_https_url(Fog::AzureRM::ENVIRONMENT_AZURE_CHINA_CLOUD)

    assert_equal url, service.get_blob_url('test_container', 'test_blob')

    options = { scheme: 'http' }
    assert_equal url.gsub('https:', 'http:'), service.get_blob_url('test_container', 'test_blob', options)
  end

  def test_get_blob_url_for_us_success
    us_storage_account_credentials = storage_account_credentials.merge(environment: Fog::AzureRM::ENVIRONMENT_AZURE_US_GOVERNMENT)
    service = Fog::AzureRM::Storage.new(us_storage_account_credentials)
    url = ApiStub::Requests::Storage::File.blob_https_url(Fog::AzureRM::ENVIRONMENT_AZURE_US_GOVERNMENT)

    assert_equal url, service.get_blob_url('test_container', 'test_blob')

    options = { scheme: 'http' }
    assert_equal url.gsub('https:', 'http:'), service.get_blob_url('test_container', 'test_blob', options)
  end

  def test_get_blob_url_for_german_success
    german_storage_account_credentials = storage_account_credentials.merge(environment: Fog::AzureRM::ENVIRONMENT_AZURE_GERMAN_CLOUD)
    service = Fog::AzureRM::Storage.new(german_storage_account_credentials)
    url = ApiStub::Requests::Storage::File.blob_https_url(Fog::AzureRM::ENVIRONMENT_AZURE_GERMAN_CLOUD)

    assert_equal url, service.get_blob_url('test_container', 'test_blob')

    options = { scheme: 'http' }
    assert_equal url.gsub('https:', 'http:'), service.get_blob_url('test_container', 'test_blob', options)
  end

  def test_get_blob_url_mock
    url = ApiStub::Requests::Storage::File.blob_https_url
    assert_equal url, @mock_service.get_blob_url('test_container', 'test_blob')

    options = { scheme: 'http' }
    http_url = url.gsub('https:', 'http:')
    assert_equal http_url, @mock_service.get_blob_url('test_container', 'test_blob', options)
  end
end
