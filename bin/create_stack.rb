#!/usr/bin/env ruby
require 'trollop'
require 'aws-cfn-resources'

@opts = Trollop::options do
  opt :stackname, "Name of the CFN stack to create", :type => String, :required => true, :short => "s"
  opt :vpc_stackname, "Name of the stack used when creating the VPC", :type => String, :required => true, :short => "v"
  opt :template, "Name of the CFN template file", :type => String, :required => true, :short => "t"
  opt :region, "AWS region where the stack will be created", :type => String, :required => true, :short => "r"
  opt :keyname, "Name of the keypair used to access instances", :type => String, :required => true, :short => "k"
  opt :instance_type, "Instance type for all instances", :type => String, :default => "t2.micro"
end

AWS.config(region: @opts[:region])

cfn = AWS::CloudFormation.new
@vpc_stack = cfn.stacks[@opts[:vpc_stackname]]
@default_sg_id = @vpc_stack.vpc('VPC').security_groups.find { |sg| sg.name == 'default' }.id

def parameters
  parameters = {
    "KeyName"              => @opts[:keyname],
    "InstanceType"         => @opts[:instance_type],
    "VpcId"                => @vpc_stack.vpc('VPC').id,
    "Az1PublicSubnetId"    => @vpc_stack.subnet('Az1PublicSubnet').id,
    "Az2PublicSubnetId"    => @vpc_stack.subnet('Az2PublicSubnet').id,
    "Az1PrivateSubnetId"   => @vpc_stack.subnet('Az1PrivateSubnet').id,
    "Az2PrivateSubnetId"   => @vpc_stack.subnet('Az2PrivateSubnet').id
  }
  return parameters
end

def template
  file = "./templates/#{@opts[:template]}"
  body = File.open(file, "r").read
  return body
end

cfn.stacks.create(@opts[:stackname], template, parameters: parameters, capabilities: ["CAPABILITY_IAM"])

print "Waiting for stack #{@opts[:stackname]} to complete"

until cfn.stacks[@opts[:stackname]].status == "CREATE_COMPLETE"
  print "."
  sleep 5
end

