require 'spec_helper'

describe Ec2::Blackout::Shutdown do

  describe "#execute" do

    it "should shut down only stoppable resources" do
      stoppable_group = stoppable_resource(Ec2::Blackout::AutoScalingGroup)
      stoppable_group.should_receive(:stop)

      unstoppable_group = unstoppable_resource(Ec2::Blackout::AutoScalingGroup)
      unstoppable_group.should_not_receive(:stop)

      stoppable_instance = stoppable_resource(Ec2::Blackout::Ec2Instance)
      stoppable_instance.should_receive(:stop)

      unstoppable_instance = unstoppable_resource(Ec2::Blackout::Ec2Instance)
      unstoppable_instance.should_not_receive(:stop)

      groups = [stoppable_group, unstoppable_group]
      instances = [stoppable_instance, unstoppable_instance]

      Ec2::Blackout::AutoScalingGroup.stub(:groups).and_return(groups)
      Ec2::Blackout::Ec2Instance.stub(:running_instances).and_return(instances)

      shutdown = Ec2::Blackout::Shutdown.new(double, Ec2::Blackout::Options.new(:regions => ["ap-southeast-2"]))
      shutdown.execute
    end

    it "should shut down instances in all regions given by the options" do
      options = Ec2::Blackout::Options.new(:regions => ["ap-southeast-1", "ap-southeast-2"])

      Ec2::Blackout::AutoScalingGroup.should_receive(:groups).with("ap-southeast-1", anything).and_return([])
      Ec2::Blackout::AutoScalingGroup.should_receive(:groups).with("ap-southeast-2", anything).and_return([])
      Ec2::Blackout::Ec2Instance.should_receive(:running_instances).with("ap-southeast-1", anything).and_return([])
      Ec2::Blackout::Ec2Instance.should_receive(:running_instances).with("ap-southeast-2", anything).and_return([])

      shutdown = Ec2::Blackout::Shutdown.new(double, options)
      shutdown.execute
    end

    it "should not stop instances if the dry run option has been specified" do
      options = Ec2::Blackout::Options.new(:dry_run => true, :regions => ["ap-southeast-2"])
      stoppable_group = stoppable_resource(Ec2::Blackout::AutoScalingGroup)
      stoppable_group.should_not_receive(:stop)

      stoppable_instance = stoppable_resource(Ec2::Blackout::Ec2Instance)
      stoppable_instance.should_not_receive(:stop)

      Ec2::Blackout::AutoScalingGroup.stub(:groups).and_return([stoppable_group])
      Ec2::Blackout::Ec2Instance.stub(:running_instances).and_return([stoppable_instance])

      shutdown = Ec2::Blackout::Shutdown.new(double, options)
      shutdown.execute
    end

  end


  def stoppable_resource(type)
    resource(type, true)
  end

  def unstoppable_resource(type)
    resource(type, false)
  end

  def resource(type, stoppable)
    resource = double(type)
    resource.should_receive(:stoppable?).and_return(stoppable)
    resource
  end

end
