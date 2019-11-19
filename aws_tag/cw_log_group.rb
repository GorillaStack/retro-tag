require "#{__dir__}/default"

module AwsTag
  class CloudWatchLogGroup < Default

    def aws_region_services_name
      %w[CloudWatchLogs]
    end

    def friendly_service_name
      'CloudWatch Log Groups'
    end

    def aws_client(region:)
      Aws::CloudWatchLogs::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end
    
    #################################

    def tag_client_method
      'list_tags_log_group'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { log_group_names: ids }
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

      unless tag_client_method_args[:log_group_names].count.zero?
        tag_client_method_args[:log_group_names].each_slice(1) do |log_group_name|
          args = { log_group_name: log_group_name.first }
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: log_group_name.first)
        end
      end
    end

    def save_tags(describe:, region:, resource_id: nil)
      describe.send_chain(tag_response_collection.split('.')).each do |tags|

        next if tags.count.zero?
        tags.each do |tag_key, tag_value|
          resource_id_final = resource_id ? resource_id : tags[tag_response_resource_name]

          @existing_tags << {
            region:        region,
            resource_id:   resource_id_final,
            key:           tag_key,
            value:         tag_value,
            resource_type: friendly_service_name
          }
        end
      end
    end
  end
end
