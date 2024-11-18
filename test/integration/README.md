# Integration Tests

To run Integration Tests, first enter the following information for your test storage account into **credentials\azure.yml** file:

- `azure_storage_account_name`
- `azure_storage_access_key`

Then run **bundle exec ruby file_name.rb** to run integration test for a specific service e.g. For integration tests for blobs, run:

**bundle exec ruby test/integration/blob.rb**

Also make sure the **DEBUG** flag is set in your fog environment to see proper logging.
