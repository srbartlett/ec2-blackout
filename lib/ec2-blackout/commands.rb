require 'ec2-blackout'
require 'commander/import'

program :name,        Ec2::Blackout.name
program :version,     Ec2::Blackout::VERSION
program :description, Ec2::Blackout.summary

default_command :help

command "on" do |c|
  c.syntax      = '[options]'
  c.summary     = 'Shutdown EC2 instances'
  c.description = 'For each AWS Region, find running EC2 instances and shut them down.'

  c.option '-r', '--regions region1,region2', Array, 'Comma separated list of regions to search. Defaults to all regions'
  c.option '-x', '--exclude-by-tag tagname1=value,tagname2', Array, 'Comma separated list of name-value tags to exclude from the blackout'
  c.option '-i', '--include-by-tag tagname1=value,tagname2', Array, 'Comma separated list of name-value tags to include in the blackout'
  c.option '-d', '--dry-run', 'Find instances without stopping them'

  c.action do |args, options|
    Ec2::Blackout::Shutdown.new(self, Ec2::Blackout::Options.new(options.__hash__)).execute
  end
end

command "off" do |c|
  c.syntax      = '[options]'
  c.summary     = 'Start up EC2 instances'
  c.description = 'For each AWS Region, find EC2 instances previously shutdown by ec2-blackout and start them up.'

  c.option '-r', '--regions region1,region2', Array, 'Comma separated list of regions to search. Defaults to all regions'
  c.option '-f', '--force', 'Force start up regardless of who shut them dowm'
  c.option '-d', '--dry-run', 'Find instances without starting them'

  c.action do |args, options|
    Ec2::Blackout::Startup.new(self, Ec2::Blackout::Options.new(options.__hash__)).execute
  end
end
