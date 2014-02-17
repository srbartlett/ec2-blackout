require 'spec_helper'

module Ec2::Blackout

  describe Ec2Instance do

    describe ".running_instances" do
      it "returns a list of instances that are in the running state" do
        expect_instance_filter('running', 'ap-southeast-2')
        Ec2Instance.running_instances("ap-southeast-2", Options.new)
      end
    end

    describe ".stopped_instances" do
      it "returns a list of instances that are in the stopped state" do
        expect_instance_filter('stopped', 'ap-southeast-2')
        Ec2Instance.stopped_instances("ap-southeast-2", Options.new)
      end
    end

    describe "#stop" do
      let!(:aws_instance) { double("ec2 instance") }
      let!(:instance) { stubbed_stoppable_instance(aws_instance) }

      it "stops the instance" do
        aws_instance.should_receive(:stop)
        instance.stop
      end

      it "tags the instance with a timestamp indicating when it was stopped" do
        aws_instance.should_receive(:add_tag).with do |tag_name, tag_attributes|
          expect(tag_name).to eq Ec2Instance::TIMESTAMP_TAG_NAME
          expect(Time.now - tag_attributes[:value]).to be < 1
        end

        instance.stop
      end

      it "saves the associated elastic IP as a tag" do
        aws_instance.stub(:has_elastic_ip?).and_return(true)
        eip = double(:allocation_id => "eipalloc-eab23c0d")
        aws_instance.stub(:elastic_ip).and_return(eip)
        aws_instance.should_receive(:add_tag).with(Ec2Instance::EIP_TAG_NAME, :value => "eipalloc-eab23c0d")
        instance.stop
      end

    end

    describe "#start" do
      let!(:aws_instance) { double("ec2 instance") }
      let!(:instance) { stubbed_startable_instance(aws_instance) }

      it "starts the instance" do
        aws_instance.should_receive(:start)
        instance.start
      end

      it "remove ec2 blackout tags from the instance" do
        tags = ec2_tags(Ec2Instance::TIMESTAMP_TAG_NAME => '2014-02-12 02:35:52 UTC', Ec2Instance::EIP_TAG_NAME => 'eipalloc-eab23c0d')
        aws_instance.stub(:tags).and_return(tags)
        tags.should_receive(:delete).with(Ec2Instance::TIMESTAMP_TAG_NAME)
        tags.should_receive(:delete).with(Ec2Instance::EIP_TAG_NAME)
        instance.start
      end

      it "reattaches the previous elastic IP" do
        tags = ec2_tags(Ec2Instance::TIMESTAMP_TAG_NAME => '2014-02-12 02:35:52 UTC', Ec2Instance::EIP_TAG_NAME => 'eipalloc-eab23c0d')
        aws_instance.stub(:tags).and_return(tags)
        aws_instance.should_receive(:associate_elastic_ip).with("eipalloc-eab23c0d")
        instance.start
      end

      it "should retry attaching the elastic IP if it fails" do
        tags = ec2_tags(Ec2Instance::TIMESTAMP_TAG_NAME => '2014-02-12 02:35:52 UTC', Ec2Instance::EIP_TAG_NAME => 'eipalloc-eab23c0d')
        aws_instance.stub(:tags).and_return(tags)
        aws_instance.should_receive(:associate_elastic_ip).and_raise(:error)
        aws_instance.should_receive(:associate_elastic_ip)
        instance.eip_retry_delay_seconds = 0
        instance.start
      end
    end

    describe "#stoppable?" do
      let!(:aws_instance) { double("ec2 instance") }
      let!(:instance) { stubbed_stoppable_instance(aws_instance) }

      it "returns true if the instance meets all conditions for being stoppable" do
        stoppable, reason = instance.stoppable?
        expect(stoppable).to be_true
      end

      it "returns false if the instance is not running" do
        aws_instance.stub(:status).and_return(:stopped)
        stoppable, reason = instance.stoppable?
        expect(stoppable).to be_false
      end

      it "returns false if the instance belongs to an autoscaling group" do
        aws_instance.stub(:tags).and_return(ec2_tags('aws:autoscaling:groupName' => 'foobar'))
        stoppable, reason = instance.stoppable?
        expect(stoppable).to be_false
      end

      it "returns false if the instance matches the exclude tags specified in the options" do
        options = Ec2::Blackout::Options.new(:exclude_by_tag =>  ["foo=bar"])
        instance = stubbed_stoppable_instance(aws_instance, options)
        aws_instance.stub(:tags).and_return(ec2_tags("foo" => "bar"))
        stoppable, reason = instance.stoppable?
        expect(stoppable).to be_false
      end

      it "returns false if the instance does not match the include tags specified in the options" do
        options = Ec2::Blackout::Options.new(:include_by_tag =>  ["foo=bar"])
        instance = stubbed_stoppable_instance(aws_instance, options)
        aws_instance.stub(:tags).and_return(ec2_tags("foo" => "baz"))
        stoppable, reason = instance.stoppable?
        expect(stoppable).to be_false
      end
    end

    describe "#startable?" do
      let!(:aws_instance) { double("ec2 instance") }
      let!(:instance) { stubbed_startable_instance(aws_instance) }

      it "returns true if the instance meets all conditions for being startable" do
        startable, reason = instance.startable?
        expect(startable).to be_true
      end

      it "returns false if the instance does not have the ec2 blackout timestamp tag" do
        aws_instance.stub(:tags).and_return(ec2_tags({}))
        startable, reason = instance.startable?
        expect(startable).to be_false
      end

      it "returns true if the force tag was specified even if the instance does not have the ec2 blackout timestamp tag" do
        options = Ec2::Blackout::Options.new(:force => true)
        instance = stubbed_startable_instance(aws_instance, options)
        aws_instance.stub(:tags).and_return(ec2_tags({}))
        startable, reason = instance.startable?
        expect(startable).to be_true
      end
    end


    def stubbed_stoppable_instance(underlying_aws_stub, options = Options.new)
      underlying_aws_stub.stub(:status).and_return(:running)
      underlying_aws_stub.stub(:has_elastic_ip?).and_return(false)
      underlying_aws_stub.stub(:tags).and_return(ec2_tags({}))
      underlying_aws_stub.stub(:add_tag)
      underlying_aws_stub.stub(:stop)
      Ec2Instance.new(underlying_aws_stub, options)
    end

    def stubbed_startable_instance(underlying_aws_stub, options = Options.new)
      underlying_aws_stub.stub(:status).and_return(:stopped)
      underlying_aws_stub.stub(:has_elastic_ip?).and_return(false)
      underlying_aws_stub.stub(:tags).and_return(ec2_tags(Ec2Instance::TIMESTAMP_TAG_NAME => '2014-02-13 02:35:52 UTC'))
      underlying_aws_stub.stub(:associate_elastic_ip)
      underlying_aws_stub.stub(:start)
      Ec2Instance.new(underlying_aws_stub, options)
    end

    def expect_instance_filter(state, region)
      instances_stub = double("instances")
      ec2_stub = double("ec2 instance", :instances => instances_stub)
      AWS::EC2.should_receive(:new).with(:region => region).and_return(ec2_stub)
      instances_stub.should_receive(:filter).with('instance-state-name', state).and_return([double, double])
    end

    def ec2_tags(tags_hash)
      # Hack to add a "to_h" method to hash instance (ruby 1.9 doesn't have it, but 2.0 does).
      # This lets us use a simple hash instead of an instance of AWS::EC2::ResourceTagCollection to
      # represent the instance tags.
      if !tags_hash.respond_to?(:to_h)
        def tags_hash.to_h
          self
        end
      end
      tags_hash
    end

  end

end
