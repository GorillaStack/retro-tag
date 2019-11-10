require "#{__dir__}/default"

module AwsTag
  class DynamoDbTable < Default

    def aws_region_services_name
      %w[DynamoDB]
    end

    def friendly_service_name
      'DynamoDB Tables'
    end

    def aws_client(region:)
      Aws::DynamoDB::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'list_tags_of_resource'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { resource_arn: ids }
    end

    def tag_response_collection
      'tags'
    end

    def tag_response_resource_name
      '' # all
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      unless tag_client_method_args[:resource_arn].count.zero?
        tag_client_method_args[:resource_arn].each_slice(1) do |resource_arn|
          tag_client_method_args[:resource_arn] = resource_arn.first
          describe = client.send(tag_client_method, **tag_client_method_args)
          save_tags(describe: describe, region: region, resource_id: resource_arn.first)
        end
      end
    end
  end

end
