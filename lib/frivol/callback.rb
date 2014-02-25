module Frivol
  class Callback
    def initialize(klass, method, default=nil)
      @klass = klass
      @method  = method
      @default = default
    end

    def compile(method_name)
      proc = case @method
      when Proc
        @method
      when Symbol
        instance_proc = proc{ |o| o.send(@method) }
      else
        default_return = @default
        default_proc = proc{ default_return }
      end
      @klass.send(:define_method, method_name, &proc)
    end
  end
end
