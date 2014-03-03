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
        proc do |frivol_method, *frivol_args|
          method.call(self, frivol_method, *frivol_args)
        end
      when Symbol
        method = @method
        proc do |frivol_method, *frivol_args|
          self.send(method, frivol_method, *frivol_args)
        end
      else
        default_return = @default
        proc{ default_return }
      end
    end
  end
end
