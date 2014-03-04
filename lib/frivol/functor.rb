module Frivol
  # == Frivol::Functor
  # Compiles proc, symbols, false, true into a proc that executes within a scope,
  # or on an object.
  class Functor
    # Create a new functor which takes:
    # method: can be a proc, symbol, false or true
    # default: the value which is returned from the compiled proc if method is
    #          not a proc, symbol, false or true. Defaults to nil
    def initialize(method, default=nil)
      @method  = method
      @default = default
    end

    # returns a compiled proc based on the initialization arguments
    def compile
      case @method
      when Proc
        method = @method
        proc do |*args|
          args.unshift(self)
          method.call(*args)
        end
      when Symbol
        method = @method
        proc do |*args|
          self.send(method, *args)
        end
      when FalseClass, TrueClass
        proc{ @method }
      else
        default_return = @default
        proc{ default_return }
      end
    end
  end
end
