require 'ec2-blackout'
require 'commander/import'

program :name,        Ec2::Blackout.name
program :version,     Ec2::Blackout::VERSION
program :description, Ec2::Blackout.summary

default_command :help

def aws
  AWS::EC2.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'],
     :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
end

DEFAULT_REGIONS = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1',
      'ap-northeast-1', 'sa-east-1'].join(',')

command "on" do |c|
  c.syntax      = '[options]'
  c.summary     = 'Shutdown EC2 instances'
  c.description = 'For each AWS Region, find running EC2 instances and shut them down.'

  c.option '-r', '--regions STRING', 'Comma separated list of regions to search. Defaults to all regions'
  c.option '-x', '--exclude-by-tag STRING', 'Exclude instances with the specified tag.'
  c.option '-d', '--dry-run', 'Find instances without stopping them'

  c.action do |args, options|
    options.default :regions => DEFAULT_REGIONS
    Ec2::Blackout::Shutdown.new(self, aws, options.__hash__).execute
  end
end

command "off" do |c|
  c.syntax      = '[options]'
  c.summary     = 'Start up EC2 instances'
  c.description = 'For each AWS Region, find EC2 instances previously shutdown by ec2-blackout and start them up.'

  c.option '-r', '--regions STRING', 'Comma separated list of regions to search. Defaults to all regions'
  c.option '-f', '--force', 'Force start up regardless of who shut them dowm'
  c.option '-d', '--dry-run', 'Find instances without starting them'

  c.action do |args, options|
    options.default :regions => DEFAULT_REGIONS
    Ec2::Blackout::Startup.new(self, aws, options.__hash__).execute
  end
end
