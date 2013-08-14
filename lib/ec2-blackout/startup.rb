
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
            @ui.say "-> Starting instance: #{instance.id}, name: #{instance.tags['Name']}."
            unless dry_run?
              instance.tags.delete('ec2:blackout:on')
              instance.start
              associate_eip(instance)
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

  def associate_eip instance
    eip = instance.tags['ec2:blackout:eip']
    if eip
      @ui.say("Associating Elastic IP #{eip} to #{instance.id}")
      attempts = 0
      begin
        instance.associate_elastic_ip(eip)
      rescue
        sleep 5
        attempts += 1
        retry if attempts < 60 # 5 mins
      end
      instance.tags.delete('ec2:blackout:eip')
    end
  end
end
