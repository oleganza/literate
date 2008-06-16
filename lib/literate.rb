module Literate
  def self.run
    Runner.run
  end
  class Runner
    # Thread-global spec declaration
    def self.spec(*args, &block)
      runner = (Thread.current["literate_spec_runner"] ||= new)
      runner.spec(*args, &block)
    end
    
    def self.run
      if r = Thread.current["literate_spec_runner"]
        r.run
      else
        []
      end
    end
    
    def initialize
      @specs = []
    end
    
    # Per-instance spec declaration
    def spec(*args, &block)
      @specs << Spec.new(*args, &block)
    end
    
    def run
      @specs.map do |spec|
        spec.run
      end
    end
  end
  
  class Spec
    attr_accessor :context, :description, :stack, :block
    
    def initialize(ctx, desc, stack, &block)
      @context     = ctx
      @description = desc
      @stack       = stack
      @block       = block
    end
    
    def run
      begin
        # It is, actually, a dirty hack.
        if Module === @context && !(Class === @context)
          ctx = @context
          Class.new{ include ctx }.new.instance_eval(&block)
        else
          @context.module_eval(&block)
        end
      rescue MatchingError => e
        "#{@description}: failure (#{e.message})"
      rescue => e
        "#{@description}: error (#{e})"
      else
        "#{@description}: success."
      end
    end
  end
  
  module Matchers
    class Base
      def initialize(obj)
        @obj = obj
      end
    end
    class Should < Base
      def ==(other)
        if @obj == other
          true
        else
          raise MatchingError.new, "Expected #{other}, got #{@obj}."
        end
      end
    end
    class ShouldNot < Base
      def ==(other)
        unless @obj == other
          true
        else
          raise MatchingError.new, "Expected not #{other}, got #{@obj}."
        end
      end
    end
  end
  
  class MatchingError < StandardError
  end

  module ::Kernel
    def spec(desc = nil, &block)
      Literate::Runner.spec(self, desc, caller, &block)
    end
  end

  spec "Object#should should generate a matcher" do
    nil.should.class.should == Literate::Matchers::Should
    1.should.class.should == Literate::Matchers::Should
    :symbol.should_not.class.should == Literate::Matchers::ShouldNot
    "string".should_not.class.should == Literate::Matchers::ShouldNot
  end

  class ::Object
    def should
      Literate::Matchers::Should.new(self)
    end
    def should_not
      Literate::Matchers::ShouldNot.new(self)
    end
  end

end


if __FILE__ == $0
  Literate.run.each do |result|
    puts result
  end
end

