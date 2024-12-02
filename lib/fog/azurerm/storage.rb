module Fog
  module AzureRM
    # This class registers models, requests and collections
    class Storage < Fog::Service
      # Recognizes when creating data client
      recognizes :azure_storage_account_name
      recognizes :azure_storage_access_key
      recognizes :azure_storage_token_signer
      recognizes :azure_storage_endpoint
      recognizes :azure_storage_domain
      recognizes :azure_storage_http_pool_size
      recognizes :environment

      recognizes :debug

      request_path 'fog/azurerm/requests/storage'
      # Azure Storage Container requests
      request :create_container
      request :release_container_lease
      request :acquire_container_lease
      request :delete_container
      request :list_containers
      request :put_container_metadata
      request :get_container_properties
      request :get_container_acl
      request :put_container_acl
      request :get_container_url
      request :check_container_exists
      # Azure Storage Blob requests
      request :list_blobs
      request :put_blob_metadata
      request :put_blob_properties
      request :get_blob_properties
      request :copy_blob
      request :copy_object
      request :copy_blob_from_uri
      request :compare_container_blobs
      request :acquire_blob_lease
      request :release_blob_lease
      request :get_blob
      request :get_blob_url
      request :get_object
      request :get_object_url
      request :get_blob_http_url
      request :get_blob_https_url
      request :create_block_blob
      request :put_blob_block
      request :put_blob_http_url
      request :put_blob_https_url
      request :put_object_url
      request :delete_blob
      request :delete_blob_https_url
      request :delete_object_url
      request :delete_object
      request :commit_blob_blocks
      request :create_page_blob
      request :put_blob_pages
      request :wait_blob_copy_operation_to_finish
      request :save_page_blob

      model_path 'fog/azurerm/models/storage'
      model :directory
      collection :directories
      model :file
      collection :files

      # This class provides the mock implementation for unit tests.
      class Mock
        def initialize(_options = {})
          begin
            require 'azure/storage/common'
            require 'azure/storage/blob'
          rescue LoadError => e
            retry if require('rubygems')
            raise e.message
          end
        end
      end

      # This class provides the actual implementation for service calls.
      class Real
        include Fog::AzureRM::Utilities::General

        def initialize(options)
          begin
            require 'azure/storage/common'
            require 'azure/storage/blob'
            require 'securerandom'
            @debug = ENV['DEBUG'] || options[:debug]
            require 'azure/core/http/debug_filter' if @debug
            require 'fog/azurerm/identity_encoding_filter'
          rescue LoadError => e
            retry if require('rubygems')
            raise e.message
          end

          return unless @azure_storage_account_name != options[:azure_storage_account_name] ||
                        @azure_storage_access_key != options[:azure_storage_access_key] ||
                        @azure_storage_token_signer != options[:azure_storage_token_signer]

          @azure_storage_account_name = options[:azure_storage_account_name]
          @azure_storage_access_key = options[:azure_storage_access_key]
          @azure_storage_token_signer = options[:azure_storage_token_signer]
          @azure_storage_endpoint = options[:azure_storage_endpoint]
          @azure_storage_domain = options[:azure_storage_domain]

          options[:environment] = 'AzureCloud' if options[:environment].nil?
          @environment = options[:environment]

          storage_blob_host =
            @azure_storage_endpoint ||
            if @azure_storage_domain.nil? || @azure_storage_domain.empty?
              get_blob_endpoint(@azure_storage_account_name, true, @environment)
            else
              get_blob_endpoint_with_domain(@azure_storage_account_name, true, @azure_storage_domain)
            end

          azure_client = Azure::Storage::Common::Client.create({
            storage_account_name: @azure_storage_account_name,
            storage_access_key: @azure_storage_access_key,
            signer: @azure_storage_token_signer,
            http_pool_size: options[:azure_storage_http_pool_size]
          }.compact)
          azure_client.storage_blob_host = storage_blob_host
          @blob_client = Azure::Storage::Blob::BlobService.new(client: azure_client)
          @blob_client.with_filter(Fog::AzureRM::IdentityEncodingFilter.new)
          @blob_client.with_filter(Azure::Storage::Common::Core::Filter::ExponentialRetryPolicyFilter.new)
          @blob_client.with_filter(Azure::Core::Http::DebugFilter.new) if @debug
        end

        private

        def signature_client(requested_expiry)
          access_key = @azure_storage_access_key.to_s
          user_delegation_key = user_delegation_key(requested_expiry)

          # invalidate cache when the delegation key changes
          unless @signature_client_delegation_key == user_delegation_key
            @signature_client_delegation_key = user_delegation_key
            @signature_client = nil
          end

          @signature_client ||= Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
            @azure_storage_account_name,
            access_key,
            user_delegation_key
          )
        end

        def user_delegation_key(requested_expiry)
          return nil unless @azure_storage_token_signer

          @user_delegation_key_mutex ||= Mutex.new
          @user_delegation_key_mutex.synchronize do
            if @user_delegation_key_expiry.nil? || @user_delegation_key_expiry < requested_expiry
              start = Time.now
              expiry = start + Azure::Storage::Blob::BlobConstants::MAX_USER_DELEGATION_KEY_SECONDS

              @user_delegation_key = @blob_client.get_user_delegation_key(
                start,
                expiry
              )
              @user_delegation_key_expiry = expiry
            end
          end

          @user_delegation_key
        end
      end
    end
  end
end
