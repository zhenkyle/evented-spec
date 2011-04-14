# There's little to no point in requiring only subset of evented-spec code yet,
# but in case you really want to, it won't stand in your way.

# These files are required
require 'evented-spec/util'
require 'evented-spec/version'
require 'evented-spec/evented_example'
require 'evented-spec/spec_helper'

# As of now, amqp depends on em and, em doesn't depend on anyone,
# neither does coolio.
# Pick the files accordingly.
require 'evented-spec/evented_example/em_example'
require 'evented-spec/evented_example/amqp_example'
require 'evented-spec/evented_example/coolio_example'

require 'evented-spec/spec_helper/event_machine_helpers'
require 'evented-spec/spec_helper/amqp_helpers'
require 'evented-spec/spec_helper/coolio_helpers'

require 'evented-spec/em_spec'
require 'evented-spec/amqp_spec'
require 'evented-spec/coolio_spec'