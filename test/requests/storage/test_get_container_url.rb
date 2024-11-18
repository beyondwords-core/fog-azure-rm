require File.expand_path '../../test_helper', __dir__

# Storage Container Class
class TestGetContainerUrl < Minitest::Test
  # This class posesses the test cases for the requests of getting storage container url.
  def setup
    Fog.mock!
    @mock_service = Fog::AzureRM::Storage.new(storage_account_credentials)
    Fog.unmock!

    @service = Fog::AzureRM::Storage.new(storage_account_credentials)

    @url = ApiStub::Requests::Storage::Directory.container_https_url
  end

  def test_get_container_url_success
    assert_equal @url, @service.get_container_url('test_container')

    options = { scheme: 'http' }
    assert_equal @url.gsub('https:', 'http:'), @service.get_container_url('test_container', options)
  end

  def test_get_container_url_mock
    assert_equal @url, @mock_service.get_container_url('test_container')

    options = { scheme: 'http' }
    http_url = @url.gsub('https:', 'http:')
    assert_equal http_url, @mock_service.get_container_url('test_container', options)
  end
end
