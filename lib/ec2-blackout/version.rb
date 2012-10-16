module Ec2
  module Blackout
    VERSION = "0.0.1"

    def self.name
      'ec2-blackout'
    end

    def self.summary
      'A command-line tool to shutdown EC2 instances.'
    end

    def self.description
      %q{
        ec2-blackout is a command line tool to shutdown EC2 instances.

        It's main purpose is to save you money by stopping EC2 instances during
        out of office hours.
      }
    end

  end
end
