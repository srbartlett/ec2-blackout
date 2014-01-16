require 'logger'

class Ec2::Blackout::AutoScalingGroup
  TIMESTAMP_TAG_NAME = 'ec2:blackout:on'
  DESIRED_CAPACITY_TAG_NAME = 'ec2:blackout:desired_capacity'

  def self.groups(region, options)
    AWS::AutoScaling.new(:region => region).groups.map do |group|
      Ec2::Blackout::AutoScalingGroup.new(group, options)
    end
  end

  def initialize(group, options)
    @group, @options = group, options
  end

  def stop
    tag
    zero_desired_capacity
  end

  def start
    restore_desired_capacity
    untag
  end

  def stoppable?
    AWS.memoize do
      if @options.matches_exclude_tags?(tags)
        [false, "matches exclude tags"]
      elsif !@options.matches_include_tags?(tags)
        [false, "does not match include tags"]
      elsif @group.desired_capacity == 0
        [false, "group has already been stopped"]
      elsif @group.min_size > 0
        [false, "minimum ASG size is greater than zero - set min_size to 0 if you want to be able to stop this AutoScalingGroup"]
      else
        true
      end
    end
  end

  def startable?
    if @group.max_size == 0
      [false, "maximum ASG size is zero"]
    elsif @options.force
      true
    elsif !tags[TIMESTAMP_TAG_NAME]
      [false, "instance was not originally stopped by ec2-blackout"]
    else
      true
    end
  end

  def to_s
    "autoscaling group #{@group.name}"
  end


  private

  def tag
    @group.update(:tags => [
      { :key => TIMESTAMP_TAG_NAME, :value => Time.now.utc.to_s, :propagate_at_launch => false },
      { :key => DESIRED_CAPACITY_TAG_NAME, :value => @group.desired_capacity.to_s, :propagate_at_launch => false }
    ])
  end

  def untag
    @group.delete_tags([
      { :key => TIMESTAMP_TAG_NAME, :value => tags[TIMESTAMP_TAG_NAME], :propagate_at_launch => false },
      { :key => DESIRED_CAPACITY_TAG_NAME, :value => tags[DESIRED_CAPACITY_TAG_NAME], :propagate_at_launch => false }
    ])
  end

  def zero_desired_capacity
    @group.set_desired_capacity(0)
  end

  def restore_desired_capacity
    previous_desired_capacity = tags[DESIRED_CAPACITY_TAG_NAME].to_i
    previous_desired_capacity = @group.min_size if previous_desired_capacity == 0
    @group.set_desired_capacity(previous_desired_capacity)
  end

  def tags
    @tags ||= begin
      tags_array = @group.tags.map { |tag| [tag[:key], tag[:value]] }
      tags_hash = Hash[tags_array]
      {"Name" => @group.name}.merge(tags_hash)
    end
  end

end
