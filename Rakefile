require 'rake'
require 'rspec/core/rake_task'
require 'aws-cfn-resources'

task :spec    => 'spec:all'
task :default => :spec

namespace :spec do
  
  cfn = AWS::CloudFormation.new
  stackname = ENV['STACK_NAME']
  private_instances = cfn.stacks[stackname].instances.select { |n,i| n.to_s.include? "Private" }
  targets = private_instances.collect { |n,i| i.private_ip_address }

  task :all     => targets
  task :default => :all

  targets.each do |target|
    original_target = target == "_default" ? target[1..-1] : target
    desc "Run serverspec tests to #{original_target}"
    RSpec::Core::RakeTask.new(target.to_sym) do |t|
      ENV['TARGET_HOST'] = original_target
      t.pattern = "spec/*_spec.rb"
    end
  end
end
