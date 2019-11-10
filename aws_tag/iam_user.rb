require "#{__dir__}/default"

module AwsTag
  class IamUser < Default

    def aws_region_services_name
      'IAM'
    end

    def friendly_service_name
      'IAM Users'
    end

    def aws_client(region:)
      Aws::IAM::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end
    
    #################################

    def tag_client_method
      'list_user_tags'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { user_name: ids }
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

      if tag_client_method_args[:user_name].count.zero?
        # puts 'no user_name found'
      else
        tag_client_method_args[:user_name].each_slice(1) do |user_name|
          args = tag_client_method_args.dup
          args.delete :user_name
          args[:user_name] = user_name.first
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: user_name.first)
        end
      end
    end
  end
end
