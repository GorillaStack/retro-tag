#!/usr/bin/env ruby

require 'bundler/setup'
require 'aws-sdk'
require 'pp'
require 'tty-spinner'
require 'pastel'
require 'terminal-table'

Dir["#{__dir__}/aws_resource/*.rb"].each { |file| require file }
Dir["#{__dir__}/aws_tags/*.rb"].each     { |file| require file }

require "#{__dir__}/auto_tag/summary.rb"

require 'docopt'
doc = <<DOCOPT
Audit an AWS account for the tags created by Auto Tag

Usage:
  #{__FILE__} [--region=REGION] [--profile=PROFILE]
                [--details] [--stack=STACK_NAME]
                [--user-arn=USER_ARN] [--ignore-cache]
                [--access-key-id=ACCESS_KEY_ID] [--secret-access-key=SECRET_ACCESS_KEY]
  #{__FILE__} -h | --help

Options:
  -h --help                              Show this screen.
  -d --details                           Show details for all resources.
  --region=REGION                        The AWS Region where the stack exists, required if using a StackSet, defaults to scan all regions for Stacks only.
  --profile=PROFILE                      The AWS credential profile.
  --stack=STACK_NAME                     The CloudFormation stack name, defaults to "autotag-test".
  --user-arn=USER_ARN                    The IAM user that executed the CloudFormation template, defaults to the local user's arn.
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
  AwsResource::DataPipeline.new(**object_args),
  AwsResource::DynamoDbTable.new(**object_args),
  AwsResource::Ec2Ami.new(**object_args),
  AwsResource::EC2Instance.new(**object_args),
  AwsResource::Ec2Snapshot.new(**object_args),
  AwsResource::Ec2Volume.new(**object_args),
  AwsResource::Eip.new(**object_args),
  AwsResource::ElasticLoadBalancing.new(**object_args),
  AwsResource::ElasticLoadBalancingV2.new(**object_args),
  AwsResource::ElasticMapReduce.new(**object_args),
  AwsResource::IamUser.new(**object_args),
  AwsResource::IamRole.new(**object_args),
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
  AwsResource::Vpn.new(**object_args)
]

object_args = {
  credentials: scan_credentials
}

tags_by_service = [
  AwsTags::AutoScaling.new(**object_args),
  AwsTags::DataPipeline.new(**object_args),
  AwsTags::DynamoDbTable.new(**object_args),
  AwsTags::Ec2Ami.new(**object_args),
  AwsTags::EC2Instance.new(**object_args),
  AwsTags::Ec2Snapshot.new(**object_args),
  AwsTags::Ec2Volume.new(**object_args),
  AwsTags::Eip.new(**object_args),
  AwsTags::ElasticLoadBalancing.new(**object_args),
  AwsTags::ElasticLoadBalancingV2.new(**object_args),
  AwsTags::ElasticMapReduce.new(**object_args),
  AwsTags::IamUser.new(**object_args),
  AwsTags::IamRole.new(**object_args),
  AwsTags::OpsWorks.new(**object_args),
  AwsTags::Rds.new(**object_args),
  AwsTags::S3Bucket.new(**object_args),
  AwsTags::SecurityGroup.new(**object_args),
  AwsTags::Vpc.new(**object_args),
  AwsTags::VpcEni.new(**object_args),
  AwsTags::VpcInternetGateway.new(**object_args),
  AwsTags::VpcNatGateway.new(**object_args),
  AwsTags::VpcNetworkAcl.new(**object_args),
  AwsTags::VpcPeering.new(**object_args),
  AwsTags::VpcRouteTable.new(**object_args),
  AwsTags::VpcSubnet.new(**object_args),
  AwsTags::Vpn.new(**object_args)
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

      begin
        aws_tags.write_cache_file(method: 'get_tags', existing_resources: aws_resources.existing_resources)
      rescue
        safe_puts "Failed to process: #{aws_tags.friendly_service_name}"
        safe_puts aws_resources.existing_resources.to_s
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
