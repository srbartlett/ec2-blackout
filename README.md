# Ec2::Blackout

Want to reduce your EC2 costs?

Do you stop EC2 instances out of business hours?

If you don't, `ec2-blackout` could save you money

`ec2-blackout` is a command-line tool to stop running EC2 instances and Auto Scaling Groups.

Use ec2-blackout to shutdown EC2 instances when they are idle, for example when you are not in the office.

If an instance has an Elastic IP address, `ec2-blackout` will reassociate the EIP when the instance is started.
Note: When an instance with an EIP is stopped AWS will automatically disassociate the EIP. AWS charge a small hourly fee for an unattached EIP.

Instances within Auto Scaling Groups are stopped by setting the group's "desired capacity" to zero, which causes all running instances to be terminated.

Certinaly not suitable for production instances but development and test instances can generally be shutdown overnight to save money.

## Installation

    $ gem install ec2-blackout

It is recommended you create an access policy using Amazon IAM

1. Sign in to your AWS management console and go to the IAM section
2. Create a group and paste in the following policy
```json
    {
      "Statement": [
        {
          "Action": [
            "autoscaling:CreateOrUpdateTags",
            "autoscaling:DeleteTags",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:SetDesiredCapacity"
          ],
          "Effect": "Allow",
          "Resource": "*"
        },
        {
          "Action": [
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:DescribeTags",
            "ec2:CreateTags",
            "ec2:DeleteTags",
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ec2:DescribeAddresses",
            "ec2:AssociateAddress"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }
```

3. Create a user account and download the access key.
4. Add the user to the previously created group.


Once installed you need to export your AWS credentials

    export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY
    export AWS_SECRET_ACCESS_KEY=YOUR_SECREY_KEY

## Stopping Auto Scaling Groups

EC2 blackout will try to stop instances that are running within auto scaling groups, as well as normal standalone instances. It accomplishes this by setting the "desired capacity" of the auto scaling group to zero, and then restoring it to its previous value when starting up again. It is important to note that you can't actually stop an auto scaled instance - they can only be terminated.

In order for auto scaled instances to be shut down, the "min size" attribute of the auto scaling group must be set to zero. If it is not, no instances within the group will be shut down.

## Usage

To get help on the commands available:

    $ ec2-blackout --help

To run a blackout across all AWS regions:

    $ ec2-blackout on

To run a blackout across a subset of AWS regions:

    $ ec2-blackout on --regions us-east-1,us-west-1

You can exclude instances from the blackout based on their EC2 tags as well. For instances that belong to an auto scaling group, the tags are matched against the Auto Scaling Group's tags, NOT the tags of the instances themselves. The name of the auto scaling group is treated as if it were a tag with key "Name". Tags are matched using regular expressions.

    # Exclude instances that have a tag with key "no_blackout"
    $ ec2-blackout on --exclude-by-tag no_blackout

    # Exclude instances whose "environment" tag "preprod"
    $ ec2-blackout on --exclude-by-tag 'environment=preprod'

    # Exclude instances whose "environment" tag is either "preprod" OR "integration"
    $ ec2-blackout on --exclude-by-tag 'environment=preprod|integration'

    # Exclude instances whose "Name" tag starts with "myapp".
    $ ec2-blackout on --exclude-by-tag 'Name=myapp.*'

    # Exclude instances whose "Name" tag starts with "myapp" AND whose "environment" tag is "preprod" or "integration"
    $ ec2-blackout on --exclude-by-tag 'Name=myapp.*,environment=preprod|integration'

Similarly, you can also specifically *include* instances in the blackout based on their tags. If this option is used, only matching instances will be stopped. The syntax is the same as for exclude tags.

    # Stop only those instances whose "Name" tag starts with "myapp" AND whose "environment" tag is "test"
    $ ec2-blackout on --include-by-tag 'Name=myapp.*,environment=test'

Excludes and includes can be used together if you like:

    # Stop all instances whose name starts with "myapp" except those whose "environment" is "preprod"
    $ ec2-blackout on --include-by-tag 'Name=myapp.*' --exclude-by-tag 'environment=preprod'

To leave a blackout and start the instances that were previously stopped:

    $ ec2-blackout off

`ec2-blackout` also provides a dry-run using the `--dry-run` option. This option shows you what will be done, but without actually doing it.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
