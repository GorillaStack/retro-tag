module AwsMixin
  def write_cache_file(method:, existing_resources: {})
    @existing_resources = existing_resources
    existing_var = "existing_#{method.split('_')[1]}"

    cache_sub_dir = (credentials.respond_to? :profile_name) ? credentials.profile_name : credentials.access_key_id
    @cache_dir = "#{__dir__}/../cache/#{cache_sub_dir}"

    FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
    file = "#{@cache_dir}/#{friendly_service_name.gsub(/\s+/, '_',).downcase}_#{method}.yaml"
    if File.exists? file
      file_mtime_diff = Time.now - File.mtime(file)
    end

    if !file_mtime_diff or file_mtime_diff > 3600 or $args['--ignore-cache'] # 1 hour(s)
      @files_cached = true
      safe_puts "The #{self.class}.#{method} cache file is too old, scanning aws..."

      self.send(method)

      existing_yaml = instance_variable_get("@#{existing_var}").to_yaml
      File.open(file, 'w') do |f|
        f.write(existing_yaml)
      end
    else
      safe_puts "The #{self.class}.#{method} cache file usable"
      existing_yaml = File.read(file)
      self.instance_variable_set("@#{existing_var}", YAML.load(existing_yaml))
    end

    safe_puts "Total #{self.class}.#{method}: #{Humanize.int(instance_variable_get("@#{existing_var}").count)}"
  end

  def get_aws_account_id(credentials:)
    iam = Aws::IAM::Client.new(region: 'us-east-1', credentials: credentials)
    user = iam.get_user
    user[:user][:arn].match('^arn:aws:iam::([0-9]{12}):.*$')[1]
  end
end


class Numeric
  def percent_of(n)
    (self.to_f / n.to_f * 100.0).round(2)
  end
end

class Object
  def send_chain(methods)
    if self.is_a? String
      self
    else
      methods.inject(self) do |obj, method|
        obj.send method
      end
    end
  end

  def safe_puts(msg)
    puts msg + "\n"
  end
end

class Humanize
  def self.int(int)
    if decimals(int).zero?
      int.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
    else
      int.round(1).to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
    end
  end

  def self.decimals(a)
    num = 0
    while(a != a.to_i)
      num += 1
      a *= 10
    end
    num
  end

  def self.time(secs)
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map do |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    end.compact.reverse.join(' ')
  end
end


