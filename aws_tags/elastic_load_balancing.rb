require "#{__dir__}/default"

module AwsTags
  class ElasticLoadBalancing < Default

    def aws_region_services_name
      %w(ElasticLoadBalancing)
    end

    def friendly_service_name
      'Elastic Load Balancing'
    end

    def aws_client(region:)
      Aws::ElasticLoadBalancing::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'describe_tags'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { load_balancer_names: ids }
    end

    def tag_response_collection
      'tag_descriptions'
    end

    def tag_response_resource_name
      'load_balancer_name'
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      if tag_client_method_args[:load_balancer_names].count.zero?
        # puts 'no resource_names found'
      else
        tag_client_method_args[:load_balancer_names].each_slice(20) do |load_balancer_names|
          args = tag_client_method_args.dup
          args[:load_balancer_names] = load_balancer_names
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region)
        end
      end
    end
  end
end
