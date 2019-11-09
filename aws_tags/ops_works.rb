require "#{__dir__}/default"

module AwsTags
  class OpsWorks < Default

    def aws_region_services_name
      %w[OpsWorks]
    end

    def friendly_service_name
      'OpsWorks Stacks'
    end

    def aws_client(region:)
      Aws::OpsWorks::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'list_tags'
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
      ''
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      unless tag_client_method_args[:resource_arn].count.zero?
        tag_client_method_args[:resource_arn].each_slice(1) do |resource_arn|
          tag_client_method_args[:resource_arn] = resource_arn.first
          describe  = client.send(tag_client_method, **tag_client_method_args)
          list_tags = describe.tags.map { |name, value| { 'key' => name, 'value' => value } }
          list_tags = { tags: list_tags, last_page?: true }
          tags = OpenStruct.new list_tags
          save_tags(describe: tags, region: region, resource_id: resource_arn.first)
        end
      end
    end
  end

end
