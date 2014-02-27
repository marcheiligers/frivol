module Frivol
  class Functor
    def initialize(klass, method, default=nil)
      @klass = klass
      @method  = method
      @default = default
    end

    def compile
      case @method
      when Proc
        method = @method
        proc{ method.call(self) }
      when Symbol
        method = @method
        proc{ self.send(method) }
      else
        default_return = @default
        proc{ default_return }
      end
    end
  end
end
