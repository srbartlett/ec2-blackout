require 'ec2-blackout'

# Make sure we don't accidentally hit a real AWS service
AWS.stub!
