require 'bundler'
Bundler.setup
Bundler.require :default, :test

spec_dir = File.expand_path("..", __FILE__)
lib_dir  = File.expand_path("../../lib", __FILE__)
if ARGV.delete('--minitest')
  require 'minitest/spec'
  require 'minitest/autorun'
  $LOAD_PATH.unshift "#{spec_dir}/minitest"
  $LOAD_PATH.unshift lib_dir
  Dir.glob("#{spec_dir}/**/*_minispec.rb").each {|spec| require spec }
else
  require 'rspec'
  require 'rspec/autorun'
  Dir.glob("#{spec_dir}/**/*_spec.rb").each {|spec| require spec }
end

