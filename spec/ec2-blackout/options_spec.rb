require 'spec_helper'

describe Ec2::Blackout::Options do

  describe "#exclude_tags" do

    it "converts exclude tags into a hash" do
      options = Ec2::Blackout::Options.new :exclude_by_tag => ["Name=foo.*", " Owner = joe ", "Stopped", "Foo="]
      expect(options.exclude_tags).to eq({"Name" => "foo.*", "Owner" => "joe", "Stopped" => nil, "Foo" => ""})
    end

  end


  describe "#matches_exclude_tags" do

    it "matches by regular expression" do
      regex_options = Ec2::Blackout::Options.new(:exclude_by_tag =>  ["Name=foo.*"])
      expect(regex_options.matches_exclude_tags?({"Name" => "foobar"})).to be_true
    end

    it "matches by tag name only if no value is given in the options" do
      tag_name_only_options = Ec2::Blackout::Options.new(:exclude_by_tag =>  ["Name"])
      expect(tag_name_only_options.matches_exclude_tags?("Name" => "foobar")).to be_true
      expect(tag_name_only_options.matches_exclude_tags?("Owner" => "bill")).to be_false
    end

    it "returns true only if all tags match" do
      multiple_tag_options = Ec2::Blackout::Options.new(:exclude_by_tag =>  ["Name=foo.*", "Owner=joe"])
      expect(multiple_tag_options.matches_exclude_tags?("Name" => "foobar", "Owner" => "joe")).to be_true
      expect(multiple_tag_options.matches_exclude_tags?("Name" => "foobar", "Owner" => "bill")).to be_false
    end

    it "returns false if there are no exclude tags specified" do
      empty_options = Ec2::Blackout::Options.new
      expect(empty_options.matches_exclude_tags?("Name" => "foobar")).to be_false
    end

    it "returns false if no tags match" do
      regex_options = Ec2::Blackout::Options.new(:exclude_by_tag =>  ["Name=foobar"])
      expect(regex_options.matches_exclude_tags?({"Name" => "blerk"})).to be_false
    end

    it "handles equals signs in the value" do
      equals_options = Ec2::Blackout::Options.new(:exclude_by_tag =>  ["Name=foo=bar"])
      expect(equals_options.matches_exclude_tags?("Name" => "foo=bar")).to be_true
    end

  end


  describe "#matches_include_tags" do

    it "matches by regular expression" do
      regex_options = Ec2::Blackout::Options.new(:include_by_tag =>  ["Name=foo.*"])
      expect(regex_options.matches_include_tags?({"Name" => "foobar"})).to be_true
    end

    it "matches by tag name only if no value is given in the options" do
      tag_name_only_options = Ec2::Blackout::Options.new(:include_by_tag =>  ["Name"])
      expect(tag_name_only_options.matches_include_tags?("Name" => "foobar")).to be_true
      expect(tag_name_only_options.matches_include_tags?("Owner" => "bill")).to be_false
    end

    it "returns true only if all tags match" do
      multiple_tag_options = Ec2::Blackout::Options.new(:include_by_tag =>  ["Name=foo.*", "Owner=joe"])
      expect(multiple_tag_options.matches_include_tags?("Name" => "foobar", "Owner" => "joe")).to be_true
      expect(multiple_tag_options.matches_include_tags?("Name" => "foobar", "Owner" => "bill")).to be_false
    end

    it "returns true if there are no include tags specified" do
      empty_options = Ec2::Blackout::Options.new
      expect(empty_options.matches_include_tags?("Name" => "foobar")).to be_true
    end

    it "returns false if no tags match" do
      regex_options = Ec2::Blackout::Options.new(:include_by_tag =>  ["Name=foo.*"])
      expect(regex_options.matches_include_tags?({"Name" => "blerk"})).to be_false
    end

    it "handles equals signs in the value" do
      equals_options = Ec2::Blackout::Options.new(:include_by_tag =>  ["Name=foo=bar"])
      expect(equals_options.matches_include_tags?("Name" => "foo=bar")).to be_true
    end

  end


  describe "#regions" do

    it "provides default regions if none are specified" do
      options = Ec2::Blackout::Options.new
      expect(options.regions).to eq Ec2::Blackout::Options::DEFAULT_REGIONS
    end

  end


end
