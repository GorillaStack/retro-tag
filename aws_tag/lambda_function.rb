require "#{__dir__}/default"

module AwsTag
  class LambdaFunction < Default

    def aws_region_services_name
      'Lambda'
    end

    def friendly_service_name
      'Lambda Functions'
    end

    def aws_client(region:)
      Aws::Lambda::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end
    
    #################################

    def tag_client_method
      'list_tags'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { function_arns: ids }
    end

    def tag_response_collection
      ''
    end

    def tag_response_resource_name
      ''
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      # pp tag_client_method_args

      if tag_client_method_args[:function_arns].count.zero?
        # puts 'no function_arns found'
      else
        tag_client_method_args[:function_arns].each_slice(1) do |function_arn|
          args = tag_client_method_args.dup
          args.delete :function_arns
          args[:resource] = function_arn.first
          describe = client.send(tag_client_method, **args)
          save_tags(describe: describe, region: region, resource_id: function_arn.first)
        end
      end
    end

    def save_tags(describe:, region:, resource_id: nil)
      describe.send_chain(tag_response_collection.split('.')).each do |tags|

        next if tags.count.zero?
        tags.each do |tag_key, tag_value|
          resource_id_final = resource_id ? resource_id : tags[tag_response_resource_name]

          # puts 'adsf'
          # puts "#{tag_key} #{tag_value} #{resource_id_final}"

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
