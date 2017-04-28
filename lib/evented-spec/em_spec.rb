module EventedSpec
  # Including EventedSpec::EMSpec module into your example group, each example of this group
  # will run inside EM.run loop without the need to explicitly call 'em'.
  #
  module EMSpec
    def self.included(example_group)
      example_group.send(:include, SpecHelper)
      example_group.extend ClassMethods
    end

    # @private
    module ClassMethods
      def it(*args, &block)
        if block
          # Shared example groups seem to pass example group instance
          # to the actual example block
          new_block = lambda do |*args_block|
            em(&block)
          end
          super(*args, &new_block)
        else
          # pending example
          super
        end
      end # it
    end # ClassMethods
  end # EMSpec
end # module EventedSpec
