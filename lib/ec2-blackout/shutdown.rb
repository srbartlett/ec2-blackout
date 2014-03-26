require 'colorize'

class Ec2::Blackout::Shutdown

  def initialize(ui, options)
    @ui, @options = ui, options
  end

  def execute
    @ui.say 'Dry run specified - no instances will be stopped'.bold if @options.dry_run
    @ui.say "Stopping instances"
    @options.regions.each do |region|
      @ui.say "Checking region #{region}"
      shutdown(Ec2::Blackout::AutoScalingGroup.groups(region, @options))
      shutdown(Ec2::Blackout::Ec2Instance.running_instances(region, @options))
    end
    @ui.say 'Done!'
  end

  private

  def shutdown(resources)
    resources.each do |resource|
      stoppable, reason = resource.stoppable?
      if stoppable
        @ui.say "-> Stopping #{resource}".yellow
        resource.stop unless @options.dry_run
      else
        @ui.say "-> Skipping #{resource}: #{reason}"
      end
    end
  end

end
