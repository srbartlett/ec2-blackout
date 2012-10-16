
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
            instance.add_tag('ec2::blackout::on', Date.now.utc)
            #instance.stop
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
    (instance.status == :running && exclude_tag && !instance.tags[exclude_tag].nil?) or
      (instance.status == :running && exclude_tag.nil?)
  end

  def exclude_tag
    @options[:exclude_by_tag]
  end
end
