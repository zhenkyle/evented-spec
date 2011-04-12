module EventedSpec
  module Util
    extend self

    # Creates a deep clone of an object. Different from normal Object#clone
    # method which is shallow clone (doesn't traverse hashes and arrays,
    # cloning their contents).
    #
    # @param Object to clone
    # @return Deep clone of the given object
    def deep_clone(value)
      case value
      when Hash
        value.inject({}) do |result, kv|
          result[kv[0]] = deep_clone(kv[1])
          result
        end
      when Array
        value.inject([]) do |result, item|
          result << deep_clone(item)
        end
      else
        begin
          value.clone
        rescue TypeError
          value
        end
      end
    end # deep_clone
  end # module Util
end # module EventedSpec