require "#{__dir__}/default"

module AwsResource
  class DynamoDbTable < Default

    def aws_region_services_name
      %w[DynamoDB]
    end

    def friendly_service_name
      'DynamoDB Tables'
    end

    def aws_client(region:)
      Aws::DynamoDB::Client.new(region: region, credentials: credentials, retry_limit: client_retry_limit)
    end

    def aws_client_method
      'list_tables'
    end

    def aws_client_method_args
      {}
    end

    def aws_response_collection
      'table_names'
    end

    def aws_response_resource_name
      ''
    end

    def aws_event_name
      %w[CreateTable]
    end

    def resource_name_exists?(**args)
      (args[:response_elements]['tableDescription'] &&
          args[:response_elements]['tableDescription']['tableArn'])
    end

    def resource_name(**args)
      args[:response_elements]['tableDescription']['tableArn'].sub(/.*table\/(.*)$/, '\1')
    end

    ##################################

    def dynamodb_arn_builder(**args)
      arn_builder = %w(arn aws dynamodb)
      arn_builder.push args[:aws_region]
      arn_builder.push args[:aws_account_id]
      arn_builder.push "table/#{args[:table_name]}"
      arn_builder.join(':')
    end

    def resource_id_helper(resource_id:, region:)
      aws_account_id = get_aws_account_id(credentials: credentials)
      dynamodb_arn_builder(table_name: resource_id, aws_account_id: aws_account_id, aws_region: region)
    end

  end

end
