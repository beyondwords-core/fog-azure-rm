if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'test'
    command_name 'Minitest'
  end
end

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'test'
    command_name 'Minitest'
  end
end

class TestRaiseLogger
  def write(message)
    raise message
  end

  def tty?
    false
  end
end

require 'fog/core/logger'
Fog::Logger[:deprecation] = TestRaiseLogger.new
Fog::Logger[:warning] = TestRaiseLogger.new

require 'minitest/autorun'
require 'azure/core/http/http_error'
require 'azure/core/http/http_response'
$LOAD_PATH.unshift(File.expand_path '../lib', __dir__)
require File.expand_path '../lib/fog/azurerm', __dir__
require File.expand_path './api_stub', __dir__

def storage_account_credentials
  {
    azure_storage_account_name: 'mockaccount',
    azure_storage_access_key: 'YWNjZXNzLWtleQ=='
  }
end

def storage_account_credentials_with_endpoint
  storage_account_credentials.merge(
    {
      azure_storage_endpoint: 'http://localhost:10000/mockaccount'
    }
  )
end

def storage_account_credentials_with_domain
  storage_account_credentials.merge(
    {
      azure_storage_domain: 'test.example.com'
    }
  )
end

def storage_account_credentials_with_token_signer
  {
    azure_storage_account_name: 'mockaccount',
    azure_storage_token_signer: mock_token_signer
  }
end

def mock_token_signer
  @mock_token_signer ||= Minitest::Mock.new(Azure::Core::Auth::Signer.new('access-token'))
end

# Mock Class for Blob
class MockBlob
  def initialize
    @properties = {}
    @metadata = {}
    yield self if block_given?
  end

  attr_accessor :name
  attr_accessor :snapshot
  attr_accessor :properties
  attr_accessor :metadata
end

# Mock Class for Response
class MockResponse
  def initialize(code, body, headers)
    @status = code
    @body = body
    @headers = headers
    @headers.each do |k, v|
      @headers[k] = [v] unless v.respond_to? 'first'
    end
  end
  attr_accessor :status
  attr_accessor :body
  attr_accessor :headers
end

def mocked_storage_http_error
  mocked_net_response = MockResponse.new 'mocked_code', 'mocked_body', a: 'a', b: 'b'
  Azure::Core::Http::HttpResponse.new mocked_net_response, 'mocked_uri'
end

def mocked_storage_http_not_found_error
  mocked_net_response = MockResponse.new '404', 'mocked_body', a: 'a', b: 'b'
  Azure::Core::Http::HttpResponse.new mocked_net_response, 'mocked_uri'
end

def directory(service)
  Fog::AzureRM::Storage::Directory.new(
    key: 'test_container',
    acl: 'container',
    etag: '0x8D29C92176C8352',
    last_modified: Time.parse('Tue, 04 Aug 2015 06:01:08 GMT'),
    lease_duration: nil,
    lease_state: 'available',
    lease_status: 'unlocked',
    metadata: {
      'key1' => 'value1',
      'key2' => 'value2'
    },
    service: service,
    collection: Fog::AzureRM::Storage::Directories.new(service: @service)
  )
end

def file(service)
  Fog::AzureRM::Storage::File.new(
    key: 'test_blob',
    directory: directory(service),
    last_modified: Time.parse('Tue, 04 Aug 2015 06:01:08 GMT'),
    etag: '0x8D29C92176C8352',
    metadata: {
      'key1' => 'value1',
      'key2' => 'value2'
    },
    lease_status: 'unlocked',
    lease_state: 'available',
    lease_duration: nil,
    content_length: 4_194_304,
    content_type: 'application/octet-stream',
    content_encoding: nil,
    content_language: nil,
    content_disposition: nil,
    content_md5: 'tXAohIyxuu/t94Lp/ujeRw==',
    cache_control: nil,
    sequence_number: 0,
    blob_type: 'BlockBlob',
    copy_id: '095adc3b-e277-4c3d-97e0-0abca881f60c',
    copy_status: 'success',
    copy_source: 'https://testaccount.blob.core.windows.net/testblob/4m?snapshot=2016-02-04T08%3A35%3A50.3157696Z',
    copy_progress: '4194304/4194304',
    copy_completion_time: 'Thu, 04 Feb 2016 08:35:52 GMT',
    copy_status_description: nil,
    accept_ranges: 0,
    service: service,
    collection: Fog::AzureRM::Storage::Files.new(service: @service, directory: directory(service))
  )
end

def storage_blob
  mock_blob = MockBlob.new
  mock_blob.name = 'test_blob'
  mock_blob.properties = {
    lease_status: 'unlocked',
    lease_state: 'available',
    lease_duration: nil,
    content_length: 4_194_304,
    content_type: 'application/octet-stream',
    content_encoding: nil,
    content_language: nil,
    content_disposition: nil,
    content_md5: 'tXAohIyxuu/t94Lp/ujeRw==',
    cache_control: nil,
    sequence_number: 0,
    blob_type: 'PageBlob',
    copy_id: '095adc3b-e277-4c3d-97e0-0abca881f60c',
    copy_status: 'success',
    copy_source: 'https://mockaccount.blob.core.windows.net/test_container/test_blob?snapshot=2016-02-04T08%3A35%3A50.3157696Z',
    copy_progress: '4194304/4194304',
    copy_completion_time: 'Thu, 04 Feb 2016 08:35:52 GMT',
    copy_status_description: nil,
    accept_ranges: 0,
    last_modified: 'Tue, 04 Aug 2015 06:01:08 GMT',
    etag: '"0x8D29C92176C8352"'
  }
  mock_blob.metadata = {
    'key1' => 'value1',
    'key2' => 'value2'
  }
  mock_blob
end
