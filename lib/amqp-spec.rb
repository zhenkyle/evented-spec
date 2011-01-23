require 'version'

__dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(__dir) unless $:.include?(__dir)

require "amqp-spec/rspec"