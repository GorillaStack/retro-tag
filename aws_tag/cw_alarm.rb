require "#{__dir__}/default"

module AwsTag
  class CloudWatchAlarm < Default

    def aws_region_services_name
      %w[CloudWatch]
    end

    def friendly_service_name
      'CloudWatch Alarms'
    end

    def aws_client(region:)
      Aws::CloudWatch::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end
    
    #################################

    def tag_client_method
      'list_tags_for_resource'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { resource_arns: ids }
    end

    def tag_response_collection
      'tags'
    end

    def tag_response_resource_name
      ''
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      unless tag_client_method_args[:resource_arns].count.zero?
        tag_client_method_args[:resource_arns].each_slice(1) do |resource_arn|
          args = { resource_arn: resource_arn.first }
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: resource_arn.first)
        end
      end
    end

  end
end
