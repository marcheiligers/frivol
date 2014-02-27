module Frivol
  class Functor
    def initialize(klass, method, default=nil)
      @klass = klass
      @method  = method
      @default = default
    end

    def compile_into_method(method_name)
      proc = case @method
      when Proc
        @method
      when Symbol
        method = @method
        instance_proc = proc{ self.send(method) }
      else
        default_return = @default
        default_proc = proc{ default_return }
      end
      @klass.send(:define_method, method_name, &proc)
    end
  end
end
