require "#{__dir__}/../auto_tag/aws_mixin.rb"
require 'terminal-table'

module AutoTag
  class Summary

    include AwsMixin

    attr_accessor :auto_tag_prefix, :summary

    def initialize
      @auto_tag_prefix = 'AutoTag_'
      @summary = {}
    end

    def join_auto_tags(resources: ,tags:)
      $spinner.start unless $spinner.spinning?
      $spinner.update(title: "Joining #{resources.friendly_service_name} resources and auto-tags...")

      if resources.existing_resources.count.zero?
        @summary[resources.friendly_service_name] = {}
      else
        resources.existing_resources.each do |resource_id, resource|
          @summary[resources.friendly_service_name] = {} unless summary.has_key? resources.friendly_service_name
          @summary[resources.friendly_service_name][resource_id] = {}
          @summary[resources.friendly_service_name][resource_id] = resources.existing_resources[resource_id].dup
        end
      end

      tags.existing_tags.each do |auto_tag|
        puts auto_tag if !auto_tag[:key]
        if auto_tag[:key].start_with? auto_tag_prefix
          # next unless auto_tag['resource_type'] == 'instance' ###TEMPPPP###

          $spinner.spin unless $args['--details']
          resource_id = auto_tag[:resource_id]
          if resources.existing_resources.has_key? resource_id
            @summary[resources.friendly_service_name][resource_id][:tags] << {
                key: auto_tag[:key],
                value: auto_tag[:value]
            }
          else
            puts $error.call("a #{auto_tag[:key]} tag exist but the #{resource_id} resource, strangely, does not exist, skipping...")
          end
        end
      end
      if $spinner.spinning?
        $spinner.update(title: "Joining of #{resources.friendly_service_name} resources and tags completed")
        $spinner.success
      end
    end

    def validate_auto_tags
      # $spinner.start unless $spinner.spinning?
      # $spinner.update(title: 'validating auto-tags...')
      summary.each do |service, service_resources|
        service_resources.each do |resource_id, resource|
          # $spinner.spin unless $args['--details']
          region = resource[:region]
          auto_tag_count = resource[:tags].select { |tag| tag[:key].start_with? auto_tag_prefix }
          name_tag_count = resource[:tags].select { |tag| tag[:key] == 'Name' }

          if $args['--details']
            if auto_tag_count.count.zero?
              puts $error.call("No AutoTags Found for #{resource_id} in #{region}")
            end
          end
          if $args['--details-all']
            if auto_tag_count.count > 0 or name_tag_count.count > 0
              tags = resource[:tags].sort_by{ |tag| [tag[:resource], tag[:key]] }
              tags.each do |tag|
                puts "#{resource_id}: #{tag}"
              end
            end
          end

          if auto_tag_count.count.zero?
            resource[:bad_result] = "No AutoTags Found for #{resource_id} in #{region}"
          end
          if auto_tag_count.count > 0 or name_tag_count.count > 0
            resource[:tags].sort_by!{ |tag| [tag[:resource_id], tag[:key]] }
          end
        end
      end

      # if $spinner.spinning?
      #   $spinner.update(title: "validation of tags completed")
      #   $spinner.success
      # end
    end

    def all_summary
      pastel = Pastel.new
      good   = pastel.green.detach
      bad    = pastel.red.detach
      rows   = []
      failed_checks = []

      summary.each_with_index do |(service, service_resources), index|
        if service == 'OpsWorks Stacks'
          required_tags_suffix = %w[Creator]
        else
          required_tags_suffix = %w[Creator CreateTime]
        end

        required_tags = required_tags_suffix.map { |suffix| "#{auto_tag_prefix}#{suffix}" }

        results_good_sum = 0
        results_bad_sum  = 0

        service_resources.each do |resource_id, resource|
          if resource[:bad_result]
            results_bad_sum += required_tags.count
            next
          end

          required_tags_dup = required_tags.dup

          resource[:tags].each do |tag|
            if tag[:key] == "#{auto_tag_prefix}Creator"
              required_tags_dup.delete(tag[:key])
              results_good_sum += 1
            elsif tag[:key] == "#{auto_tag_prefix}CreateTime" and service != 'OpsWorks Stacks'
              required_tags_dup.delete(tag[:key])
              results_good_sum += 1
            elsif tag[:key] == "#{auto_tag_prefix}InvokedBy"
              # Do Nothing
            elsif tag[:key] == 'Name'
              # Do nothing
            else
              failed_checks << tag
              results_bad_sum += 1
            end
          end
          if required_tags_dup.count > 0
            results_bad_sum += 1
            resource[:bad_result] = "Required tag(s) #{required_tags_dup} missing for #{resource_id} in #{resource[:region]}"
          end
        end

        results_bad  = service_resources.select { |_resource_id, resource| resource.has_key? :bad_result }
        coverage_percentage = results_good_sum.percent_of(results_bad_sum + results_good_sum)
        coverage = case
                     when coverage_percentage < 60
                       $red.call("#{coverage_percentage}%")
                     when coverage_percentage >= 60 && coverage_percentage < 80
                       $yellow.call("#{coverage_percentage}%")
                     when coverage_percentage >= 80
                       $green.call("#{coverage_percentage}%")
                   end

        rows << [
            "#{service}",
            "#{good.call(Humanize.int(results_good_sum).rjust(6))}",
            "#{bad.call(Humanize.int(results_bad_sum).rjust(6))}",
            "#{coverage.rjust(17) unless coverage.nil?}"
        ]
        rows << :separator unless (summary.count - 1) == index

        if $args['--details']
          puts $error.call("Failed Checks:") if failed_checks.count > 0
          puts failed_checks if failed_checks.count > 0
          puts $error.call("Bad Results:") if results_bad_sum > 0
          pp results_bad if results_bad.count   > 0
        end
      end

      puts Terminal::Table.new(
          :title => $bold.call('Auto-Tag Audit Summary'),
          :headings => %W[#{$heading.call('Service')} #{$heading.call('Passed')} #{$heading.call('Failed')} #{$heading.call('Coverage')}],
          :rows => rows
      )
    end
  end
end

