require "#{__dir__}/default"

module AwsTag
  class DataPipeline < Default

    def aws_region_services_name
      %w[DataPipeline]
    end

    def friendly_service_name
      'Data Pipelines'
    end

    def aws_client(region:)
      Aws::DataPipeline::Client.new(region: region, credentials: credentials)
    end

    #################################

    def tag_client_method
      'describe_pipelines'
    end

    def tag_client_method_args(region)
      ids = @existing_resources.select { |_resource_id, resource| resource[:region] == region }
      { pipeline_ids: ids.keys } # TODO: this is bad
    end

    def tag_response_collection
      'pipeline_description_list'
    end

    def tag_response_resource_name
      'pipeline_id'
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      unless tag_client_method_args[:pipeline_ids].count.zero?
        tag_client_method_args[:pipeline_ids].each_slice(25) do |pipeline_ids|
          tag_client_method_args[:pipeline_ids] = pipeline_ids
          describe = client.send(tag_client_method, **tag_client_method_args)
          save_tags(describe: describe, region: region)
        end
      end
    end
  end

end
