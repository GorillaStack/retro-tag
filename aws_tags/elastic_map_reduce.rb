require "#{__dir__}/default"

module AwsTags
  class ElasticMapReduce < Default

    def aws_region_services_name
      %w[EMR]
    end

    def friendly_service_name
      'EMR Clusters'
    end

    def aws_client(region:)
      Aws::EMR::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'describe_cluster'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { cluster_ids: ids }
    end

    def tag_response_collection
      'cluster.tags'
    end

    def tag_response_resource_name
      ''
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      if tag_client_method_args[:cluster_ids].count.zero?
        # puts 'no cluster_ids found'
      else
        tag_client_method_args[:cluster_ids].each_slice(1) do |cluster_ids|
          args = tag_client_method_args.dup
          args.delete :cluster_ids
          args[:cluster_id] = cluster_ids.first
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: cluster_ids.first)
        end
      end
    end
  end

end
