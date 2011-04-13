# Monkey patching some methods into Cool.io to make it more testable
module Coolio
  class Loop
    # Cool.io provides no means to change the default loop which makes sense in
    # most situations, but not ours.
    def self.default_loop=(event_loop)
      if RUBY_VERSION >= "1.9.0"
        Thread.current.instance_variable_set :@_coolio_loop, event_loop
      else
        @@_coolio_loop = event_loop
      end
    end
  end
end