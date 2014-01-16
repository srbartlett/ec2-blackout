require 'spec_helper'

describe Ec2::Blackout::Startup do

  describe "#execute" do

    it "should start up only startable resources" do
      startable_group = startable_resource(Ec2::Blackout::AutoScalingGroup)
      startable_group.should_receive(:start)

      unstartable_group = unstartable_resource(Ec2::Blackout::AutoScalingGroup)
      unstartable_group.should_not_receive(:start)

      startable_instance = startable_resource(Ec2::Blackout::Ec2Instance)
      startable_instance.should_receive(:start)

      unstartable_instance = unstartable_resource(Ec2::Blackout::Ec2Instance)
      unstartable_instance.should_not_receive(:start)

      groups = [startable_group, unstartable_group]
      instances = [startable_instance, unstartable_instance]

      Ec2::Blackout::AutoScalingGroup.stub(:groups).and_return(groups)
      Ec2::Blackout::Ec2Instance.stub(:stopped_instances).and_return(instances)

      startup = Ec2::Blackout::Startup.new(double, Ec2::Blackout::Options.new(:regions => ["ap-southeast-2"]))
      startup.execute
    end

    it "should start up instances in all regions given by the options" do
      options = Ec2::Blackout::Options.new(:regions => ["ap-southeast-1", "ap-southeast-2"])

      Ec2::Blackout::AutoScalingGroup.should_receive(:groups).with("ap-southeast-1", anything).and_return([])
      Ec2::Blackout::AutoScalingGroup.should_receive(:groups).with("ap-southeast-2", anything).and_return([])
      Ec2::Blackout::Ec2Instance.should_receive(:stopped_instances).with("ap-southeast-1", anything).and_return([])
      Ec2::Blackout::Ec2Instance.should_receive(:stopped_instances).with("ap-southeast-2", anything).and_return([])

      startup = Ec2::Blackout::Startup.new(double, options)
      startup.execute
    end

    it "should not start instances if the dry run option has been specified" do
      options = Ec2::Blackout::Options.new(:dry_run => true, :regions => ["ap-southeast-2"])
      startable_group = startable_resource(Ec2::Blackout::AutoScalingGroup)
      startable_group.should_not_receive(:start)

      startable_instance = startable_resource(Ec2::Blackout::Ec2Instance)
      startable_instance.should_not_receive(:start)

      Ec2::Blackout::AutoScalingGroup.stub(:groups).and_return([startable_group])
      Ec2::Blackout::Ec2Instance.stub(:stopped_instances).and_return([startable_instance])

      startup = Ec2::Blackout::Startup.new(double, options)
      startup.execute
    end

  end


  def startable_resource(type)
    resource(type, true)
  end

  def unstartable_resource(type)
    resource(type, false)
  end

  def resource(type, startable)
    resource = double(type)
    resource.should_receive(:startable?).and_return(startable)
    resource
  end

end
