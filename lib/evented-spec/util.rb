module EventedSpec
  module Util
    extend self

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