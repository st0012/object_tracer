class ObjectTracer
  class MethodHijacker
    attr_reader :target

    def initialize(target)
      @target = target
    end

    def hijack_methods!
      target.methods.each do |method_name|
        if is_writer_method?(method_name)
          redefine_writer_method!(method_name)
        elsif is_reader_method?(method_name)
          redefine_reader_method!(method_name)
        end
      end
    end

    private

    def is_writer_method?(method_name)
      has_definition_source?(method_name) && method_name.match?(/\w+=/) && target.method(method_name).source.match?(/attr_writer|attr_accessor/)
    rescue MethodSource::SourceNotFoundError
      false
    end

    def is_reader_method?(method_name)
      has_definition_source?(method_name) && target.method(method_name).source.match?(/attr_reader|attr_accessor/)
    rescue MethodSource::SourceNotFoundError
      false
    end

    def has_definition_source?(method_name)
      target.method(method_name).source_location
    end

    def redefine_writer_method!(method_name)
      ivar_name = "@#{method_name.to_s.sub("=", "")}"

      target.instance_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}(val)
          #{ivar_name} = val
        end
      RUBY
    end

    def redefine_reader_method!(method_name)
      target.instance_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          @#{method_name}
        end
      RUBY
    end
  end
end
