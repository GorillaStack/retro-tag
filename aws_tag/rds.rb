require "#{__dir__}/default"

module AwsTag
  class Rds < Default

    def aws_region_services_name
      %w[RDS]
    end

    def friendly_service_name
      'RDS Instances'
    end

    def aws_client(region:)
      Aws::RDS::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'list_tags_for_resource'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |resource_id, resource| resource[:region] == region }
      { resource_names: ids.keys }
    end

    def tag_response_collection
      'tag_list'
    end

    def tag_response_resource_name
      'resource_id'
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      if tag_client_method_args[:resource_names].count.zero?
        # puts 'no resource_names found'
      else
        tag_client_method_args[:resource_names].each_slice(1) do |resource_names|
          args = tag_client_method_args.dup
          args.delete :resource_names
          args[:resource_name] = resource_names.first
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: resource_names.first)
        end
      end
    end
  end
end
