#!/usr/bin/env ruby

require 'bundler/setup'
require 'aws-sdk-lambda'
require 'aws-sdk-autoscaling'
require 'aws-sdk-cloudwatch'
require 'aws-sdk-cloudwatchevents'
require 'aws-sdk-cloudwatchlogs'
require 'aws-sdk-datapipeline'
require 'aws-sdk-dynamodb'
require 'aws-sdk-ec2'
require 'aws-sdk-elasticloadbalancing'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-emr'
require 'aws-sdk-iam'
require 'aws-sdk-opsworks'
require 'aws-sdk-rds'
require 'aws-sdk-s3'
require 'pp'
require 'tty-spinner'
require 'pastel'
require 'terminal-table'

Dir["#{__dir__}/aws_resource/*.rb"].each { |file| require file }
Dir["#{__dir__}/aws_tag/*.rb"].each     { |file| require file }

require "#{__dir__}/auto_tag/summary.rb"

require 'docopt'
doc = <<DOCOPT
Audit an AWS account for the tags created by Auto Tag

Usage:
  #{__FILE__} [--profile=PROFILE]
                [--details] [--details-all]
                [--user-arn=USER_ARN] [--ignore-cache]
                [--access-key-id=ACCESS_KEY_ID] [--secret-access-key=SECRET_ACCESS_KEY]
  #{__FILE__} -h | --help

Options:
  -h --help                              Show this screen.
  -d --details                           Show more details for all resources.
  --details-all                          Show even more details for all resources.
  --profile=PROFILE                      The AWS credential profile.
  --user-arn=USER_ARN                    The IAM user that executed the CloudFormation template, defaults to the selected AWS profile's user arn.
  --ignore-cache                         Ignore the cache files and start the discovery process from the beginning.
  --access-key-id=ACCESS_KEY_ID          The AWS access key ID for the scanner to verify resources existence
  --secret-access-key=SECRET_ACCESS_KEY  The AWS secret access key for the scanner to verify resources existence

DOCOPT

begin
  $args = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
end

scan_profile      = $args['--profile'] ? $args['--profile'] : 'default'
thread_count      = $args['--threads'] ? $args['--threads'] : 10
access_key_id     = $args['--access-key-id']     ? $args['--access-key-id']     : nil
secret_access_key = $args['--secret-access-key'] ? $args['--secret-access-key'] : nil

if access_key_id and secret_access_key
  scan_credentials = Aws::Credentials.new(access_key_id, secret_access_key)
else
  scan_credentials = Aws::SharedCredentials.new(profile_name: scan_profile)
end

$spinner = TTY::Spinner.new(':spinner :title', format: :bouncing_ball)

pastel   = Pastel.new
$bold    = pastel.bold.underline.detach
$heading = pastel.blue.bold.detach
$error   = pastel.red.detach
$red     = pastel.red.detach
$yellow  = pastel.yellow.detach
$green   = pastel.green.detach

object_args = {
  csv: nil,
  credentials: scan_credentials,
  bucket_name: nil,
  profile: scan_profile
}

resources_by_service = [
  AwsResource::AutoScaling.new(**object_args),
  AwsResource::CloudWatchAlarm.new(**object_args),
  AwsResource::CloudWatchLogGroup.new(**object_args),
  AwsResource::CloudWatchEventsRule.new(**object_args),
  AwsResource::DataPipeline.new(**object_args),
  AwsResource::DynamoDbTable.new(**object_args),
  AwsResource::Ec2Ami.new(**object_args),
  AwsResource::Ec2CustomerGateway.new(**object_args),
  AwsResource::Ec2DhcpOptions.new(**object_args),
  AwsResource::EC2Instance.new(**object_args),
  AwsResource::Ec2Snapshot.new(**object_args),
  AwsResource::Ec2Volume.new(**object_args),
  AwsResource::Eip.new(**object_args),
  AwsResource::ElasticLoadBalancing.new(**object_args),
  AwsResource::ElasticLoadBalancingV2.new(**object_args),
  AwsResource::ElasticMapReduce.new(**object_args),
  AwsResource::IamUser.new(**object_args),
  AwsResource::IamRole.new(**object_args),
  AwsResource::LambdaFunction.new(**object_args),
  AwsResource::OpsWorks.new(**object_args),
  AwsResource::Rds.new(**object_args),
  AwsResource::S3Bucket.new(**object_args),
  AwsResource::SecurityGroup.new(**object_args),
  AwsResource::Vpc.new(**object_args),
  AwsResource::VpcEni.new(**object_args),
  AwsResource::VpcInternetGateway.new(**object_args),
  AwsResource::VpcNatGateway.new(**object_args),
  AwsResource::VpcNetworkAcl.new(**object_args),
  AwsResource::VpcPeering.new(**object_args),
  AwsResource::VpcRouteTable.new(**object_args),
  AwsResource::VpcSubnet.new(**object_args),
  AwsResource::VpnConnection.new(**object_args),
  AwsResource::VpnGateway.new(**object_args),
]

object_args = {
  credentials: scan_credentials
}

tags_by_service = [
  AwsTag::AutoScaling.new(**object_args),
  AwsTag::CloudWatchAlarm.new(**object_args),
  AwsTag::CloudWatchLogGroup.new(**object_args),
  AwsTag::CloudWatchEventsRule.new(**object_args),
  AwsTag::DataPipeline.new(**object_args),
  AwsTag::DynamoDbTable.new(**object_args),
  AwsTag::Ec2Ami.new(**object_args),
  AwsTag::Ec2CustomerGateway.new(**object_args),
  AwsTag::Ec2DhcpOptions.new(**object_args),
  AwsTag::EC2Instance.new(**object_args),
  AwsTag::Ec2Snapshot.new(**object_args),
  AwsTag::Ec2Volume.new(**object_args),
  AwsTag::Eip.new(**object_args),
  AwsTag::ElasticLoadBalancing.new(**object_args),
  AwsTag::ElasticLoadBalancingV2.new(**object_args),
  AwsTag::ElasticMapReduce.new(**object_args),
  AwsTag::IamUser.new(**object_args),
  AwsTag::IamRole.new(**object_args),
  AwsTag::LambdaFunction.new(**object_args),
  AwsTag::OpsWorks.new(**object_args),
  AwsTag::Rds.new(**object_args),
  AwsTag::S3Bucket.new(**object_args),
  AwsTag::SecurityGroup.new(**object_args),
  AwsTag::Vpc.new(**object_args),
  AwsTag::VpcEni.new(**object_args),
  AwsTag::VpcInternetGateway.new(**object_args),
  AwsTag::VpcNatGateway.new(**object_args),
  AwsTag::VpcNetworkAcl.new(**object_args),
  AwsTag::VpcPeering.new(**object_args),
  AwsTag::VpcRouteTable.new(**object_args),
  AwsTag::VpcSubnet.new(**object_args),
  AwsTag::VpnConnection.new(**object_args),
  AwsTag::VpnGateway.new(**object_args),
]


####
# resources
####

resources_start_time = Time.now
mutex        = Mutex.new
threads      = []
temp         = []

thread_count.times do |i|
  threads[i] = Thread.new {
    until resources_by_service.count.zero?

      aws_resource = resources_by_service.pop
      next unless aws_resource

      aws_resource.write_cache_file(method: 'get_resources')

      mutex.synchronize do
        temp << aws_resource
      end
    end
  }
end

threads.each(&:join)
resources_by_service = temp.dup.sort_by { |aws_resource| "#{aws_resource.friendly_service_name}" }

resources_finish_time = Time.now - resources_start_time
puts $heading.call("Completed collecting resources in #{Humanize.time(resources_finish_time)}")


####
# tags
####

tags_start_time = Time.now
mutex        = Mutex.new
threads      = []
temp         = []

thread_count.times do |i|
  threads[i] = Thread.new {
    until tags_by_service.count.zero?

      aws_tags = tags_by_service.pop
      next unless aws_tags

      aws_resources = resources_by_service.find do |aws_resources_find|
        aws_resources_find.friendly_service_name == aws_tags.friendly_service_name
      end

      unless aws_resources
        puts "Couldn't find matching resources for #{aws_tags.friendly_service_name}, exiting..."
        exit 1
      end

      begin
        aws_tags.write_cache_file(method: 'get_tags', existing_resources: aws_resources.existing_resources)
      rescue
        safe_puts "Failed to process: #{aws_tags.friendly_service_name}"
        safe_puts aws_resources.existing_resources.to_s if aws_resources.existing_resources
        raise
      end

      mutex.synchronize do
        temp << aws_tags
      end
    end
  }
end

threads.each(&:join)
tags_by_service = temp.dup

puts $heading.call("Completed collecting resources in #{Humanize.time(resources_finish_time)}")
puts $heading.call("Completed collecting tags in #{Humanize.time(Time.now - tags_start_time)}")


####
# summary
####

autotag_summary = AutoTag::Summary.new

resources_by_service.each do |aws_resources|
  aws_tags = tags_by_service.find do |aws_tags_find|
    aws_tags_find.friendly_service_name == aws_resources.friendly_service_name
  end
  autotag_summary.join_auto_tags(resources: aws_resources, tags: aws_tags)
end

autotag_summary.validate_auto_tags
autotag_summary.all_summary
