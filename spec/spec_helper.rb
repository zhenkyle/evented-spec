#$LOAD_PATH << "." unless $LOAD_PATH.include? "." # moronic 1.9.2 breaks things bad

require 'bundler'
Bundler.setup
Bundler.require :default, :test

require 'yaml'
require 'evented-spec'
require 'shared_examples'

require 'amqp'
begin
  require 'cool.io'
rescue LoadError => e
  if RUBY_PLATFORM =~ /java/
    puts "Cool.io is unavailable for jruby"
  else
    # cause unknown, reraise
    raise e
  end
end

# Done is defined as noop to help share examples between evented and non-evented specs
def done
end

RSpec.configure do |c|
  c.filter_run_excluding :nojruby => true if RUBY_PLATFORM =~ /java/
end

amqp_config = File.dirname(__FILE__) + '/amqp.yml'

AMQP_OPTS   = unless File.exists? amqp_config
                {:user  => 'guest',
                 :pass  => 'guest',
                 :host  => 'localhost',
                 :vhost => '/'}
              else
                class Hash
                  def symbolize_keys
                    self.inject({}) { |result, (key, value)|
                      new_key         = case key
                                          when String then
                                            key.to_sym
                                          else
                                            key
                                        end
                      new_value       = case value
                                          when Hash then
                                            value.symbolize_keys
                                          else
                                            value
                                        end
                      result[new_key] = new_value
                      result
                    }
                  end
                end

                YAML::load_file(amqp_config).symbolize_keys[:test]
              end