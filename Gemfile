source :rubygems

# Use local clones if possible.
def custom_gem(name, options = Hash.new)
  local_path = File.expand_path("../../#{name}", __FILE__)
  if File.directory?(local_path)
    gem name, options.merge(:path => local_path).delete_if { |key, _| [:git, :branch].include?(key) }
  else
    gem name, options
  end
end

group :test do
  # Should work for either RSpec1 or Rspec2, but you cannot have both at once.
  # Also, keep in mind that if you install Rspec 2 it prevents Rspec 1 from running normally.
  # Unless you use it like 'bundle exec spec spec', that is.

  if RUBY_PLATFORM =~ /mswin|windows|mingw/
    # For color support on Windows (deprecated?)
    gem 'win32console'
    gem 'rspec', '~>1.3.0', :require => 'spec'
  else
    gem 'rspec', '~> 2.5.0'
  end

  gem "cool.io"
  custom_gem "amq-client", :git => "git://github.com/ruby-amqp/amqp.git"
  custom_gem "amq-protocol", :git => "git://github.com/ruby-amqp/amqp.git"
  custom_gem "amqp", :git => "git://github.com/ruby-amqp/amqp.git", :branch => "master"
end