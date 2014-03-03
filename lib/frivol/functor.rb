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
        proc do |*frivol_args|
          frivol_args.unshift(self)
          method.call(*frivol_args)
        end
      when Symbol
        method = @method
        proc do |*frivol_args|
          self.send(method, *frivol_args)
        end
      when FalseClass
        proc{ false }
      else
        default_return = @default
        proc{ default_return }
      end
    end
  end
end
