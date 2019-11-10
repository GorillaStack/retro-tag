require "#{__dir__}/default"

module AwsTag
  class IamRole < Default

    def aws_region_services_name
      'IAM'
    end

    def friendly_service_name
      'IAM Roles'
    end

    def aws_client(region:)
      Aws::IAM::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end
    
    #################################

    def tag_client_method
      'list_role_tags'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { role_name: ids }
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

      # pp tag_client_method_args

      if tag_client_method_args[:role_name].count.zero?
        # puts 'no role_name found'
      else
        tag_client_method_args[:role_name].each_slice(1) do |role_name|
          args = tag_client_method_args.dup
          args.delete :role_name
          args[:role_name] = role_name.first
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: role_name.first)
        end
      end
    end
  end

end
