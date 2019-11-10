require "#{__dir__}/default"

module AwsTag
  class ElasticLoadBalancingV2 < Default

    def aws_region_services_name
      %w(ElasticLoadBalancingV2)
    end

    def friendly_service_name
      'Elastic Load Balancing V2'
    end

    def aws_client(region:)
      Aws::ElasticLoadBalancingV2::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'describe_tags'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { resource_arns: ids }
    end

    def tag_response_collection
      'tag_descriptions'
    end

    def tag_response_resource_name
      'resource_arn'
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      if tag_client_method_args[:resource_arns].count.zero?
        # puts 'no resource_names found'
      else
        describe = client.send(tag_client_method, **og_tag_client_method_args)
        save_tags(describe: describe, region: region)
      end
    end
  end
end
