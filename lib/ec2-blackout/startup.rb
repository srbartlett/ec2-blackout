require 'colorize'

class Ec2::Blackout::Startup

  def initialize(ui, options)
    @ui, @options = ui, options
  end

  def execute
    @ui.say 'Dry run specified - no instances will be started'.bold if @options.dry_run
    @ui.say "Starting instances"
    @options.regions.each do |region|
      @ui.say "Checking region #{region}"
      startup(Ec2::Blackout::AutoScalingGroup.groups(region, @options))
      startup(Ec2::Blackout::Ec2Instance.stopped_instances(region, @options))
    end
    @ui.say 'Done!'
  end

  private

  def startup(resources)
    resources.each do |resource|
      startable, reason = resource.startable?
      if startable
        @ui.say "-> Starting #{resource}".green
        resource.start unless @options.dry_run
      else
        @ui.say "-> Skipping #{resource}: #{reason}"
      end
    end
  end

end
