require "logger"

class Ec2::Blackout::Ec2Instance

  TIMESTAMP_TAG_NAME = 'ec2:blackout:on'
  EIP_TAG_NAME = 'ec2:blackout:eip'

  def self.running_instances(region, options)
    instances(region, options, 'running')
  end

  def self.stopped_instances(region, options)
    instances(region, options, 'stopped')
  end


  attr_accessor :eip_retry_delay_seconds

  def initialize(instance, options)
    @instance, @options = instance, options
    @eip_retry_delay_seconds = 5
  end

  def stop
    tag
    @instance.stop
  end

  def start
    @instance.start
    associate_eip
    untag
  end

  def stoppable?
    if tags['aws:autoscaling:groupName']
      [false, "instance is part of an autoscaling group"]
    elsif @instance.status != :running
      [false, "instance is not in running state"]
    elsif @options.matches_exclude_tags?(tags)
      [false, "matches exclude tags"]
    elsif !@options.matches_include_tags?(tags)
      [false, "does not match include tags"]
    elsif @instance.root_device_type != :ebs
      [false, "is not ebs root device"]
    else
      true
    end
  end

  def startable?
    if @instance.status != :stopped
      [false, "instance is not in stopped state"]
    elsif @options.force
      true
    elsif !tags[TIMESTAMP_TAG_NAME]
      [false, "instance was not originally stopped by ec2-blackout"]
    else
      true
    end
  end

  def to_s
    s = "instance #{@instance.id}"
    s += " (#{tags['Name']})" if tags['Name']
    s
  end


  private

  def self.instances(region, options, instance_status)
    AWS::EC2.new(:region => region).instances.filter('instance-state-name', instance_status).map do |instance|
      Ec2::Blackout::Ec2Instance.new(instance, options)
    end
  end


  def tag
    @instance.add_tag(TIMESTAMP_TAG_NAME, :value => Time.now.utc)
    if @instance.has_elastic_ip?
      @instance.add_tag(EIP_TAG_NAME, :value => @instance.elastic_ip.allocation_id)
    end
  end

  def untag
    @instance.tags.delete(TIMESTAMP_TAG_NAME)
    @instance.tags.delete(EIP_TAG_NAME)
  end

  def tags
    @tags ||= @instance.tags.to_h
  end

  def associate_eip
    eip = @instance.tags[EIP_TAG_NAME]
    if eip
      attempts = 0
      begin
        @instance.associate_elastic_ip(eip)
      rescue
        sleep eip_retry_delay_seconds
        attempts += 1
        retry if attempts * eip_retry_delay_seconds < 5*60 # 5 mins
      end
    end
  end

end
