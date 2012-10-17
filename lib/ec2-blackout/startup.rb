
class Ec2::Blackout::Startup

  def initialize(ui, aws, options)
    @ui, @aws, @options = ui, aws, options
  end

  def execute
    regions.each do |region|
      @ui.say "Checking region: #{region}"
      AWS.memoize do
        @aws.regions[region].instances.each do |instance|
          if startable? instance
            @ui.say "-> Starting instance: #{instance.id}, name: #{instance.tags['Name']}"
            unless dry_run?
              instance.tags.delete('ec2:blackout:on')
              instance.start
            end
          elsif instance.status == :stopped
            @ui.say "-> Skipping instance: #{instance.id}, name: #{instance.tags['Name'] || 'N/A'}"
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

  def startable? instance
    (instance.status == :stopped && instance.tags.to_h.key?('ec2:blackout:on')) or
      (instance.status == :stopped && @options[:force])
  end

  def dry_run?
    @options[:dry_run]
  end
end
