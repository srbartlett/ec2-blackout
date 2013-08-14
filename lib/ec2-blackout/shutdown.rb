
class Ec2::Blackout::Shutdown

  def initialize(ui, aws, options)
    @ui, @aws, @options = ui, aws, options
  end

  def execute
    regions.each do |region|
      @ui.say "Checking region: #{region}"
      AWS.memoize do
        @aws.regions[region].instances.each do |instance|
          if stoppable? instance
            @ui.say "-> Stopping instance: #{instance.id}, name: #{instance.tags['Name']}"
            unless dry_run?
              tag(instance)
              instance.stop
            end
          elsif instance.status == :running
            @ui.say "-> Skipping instance: #{instance.id}, name: #{instance.tags['Name']}, region: #{region}"
          end
        end
      end
    end
    @ui.say 'Done!'
  end

  private

  def regions
    @options[:regions] ? @options[:regions].split(',') : Ec2::Blackout.regions
  end

  def stoppable? instance
    (instance.status == :running && exclude_tag && !instance.tags.to_h.key?(exclude_tag)) or
      (instance.status == :running && exclude_tag.nil?)
  end

  def exclude_tag
    @options[:exclude_by_tag]
  end

  def dry_run?
    @options[:dry_run]
  end

  def tag instance
    instance.add_tag('ec2:blackout:on', :value => Time.now.utc)
    if instance.has_elastic_ip?
      instance.add_tag('ec2:blackout:eip', :value => instance.elastic_ip)
    end
  end
end
