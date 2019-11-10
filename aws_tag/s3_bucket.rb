require "#{__dir__}/default"

module AwsTag
  class S3Bucket < Default

    def aws_region_services_name
      %w[S3]
    end

    def friendly_service_name
      'S3 Buckets'
    end

    def aws_client(region:)
      Aws::S3::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    #################################

    def tag_client_method
      'get_bucket_tagging'
    end

    def tag_client_method_args(region)
      ids = existing_resources.select { |_resource_id, resource| resource[:region] == region }
      ids = ids.keys
      { buckets: ids }
    end

    def tag_response_collection
      'tag_set'
    end

    def tag_response_resource_name
      ''
    end

    ##################################

    def tags_client(client:, region:)
      og_tag_client_method_args = tag_client_method_args(region)
      tag_client_method_args    = og_tag_client_method_args.dup

      if tag_client_method_args[:buckets].count.zero?
        # puts 'no resource_names found'
      else
        tag_client_method_args[:buckets].each_slice(1) do |buckets|
          args = tag_client_method_args.dup
          args.delete :buckets
          args[:bucket] = buckets.first
          begin
            describe = client.send(tag_client_method, **args)
          rescue Aws::S3::Errors::NoSuchTagSet
            next
          end
          save_tags(describe: describe, region: region, resource_id: buckets.first)
        end
      end
    end
  end

end
