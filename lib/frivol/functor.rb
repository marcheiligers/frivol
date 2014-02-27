module Frivol
  class Functor
    def initialize(klass, method, default=nil)
      @klass = klass
      @method  = method
      @default = default
    end

    def compile_into_method(method_name)
      args = ''
      proc = case @method
      when Proc
        args = '(self)' if @method.arity == 1
        @method
      when Symbol
        method = @method
        proc{ self.send(method) }
      else
        default_return = @default
        proc{ default_return }
      end

      @klass.send(:define_method, method_name, &proc)
      "#{method_name}#{args}"
    end
  end
end
