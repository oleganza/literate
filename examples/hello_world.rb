require File.dirname(__FILE__) + '/../lib/literate'

module HelloWorld
  spec "Box says 'Hello, world!' by default" do 
    Box.new.say.should == "Hello, world!"
  end
  
  spec "Box says custom message when instantiated with an argument" do 
    Box.new("Hi!").say.should == "Hi!"
  end
  
  class Box
    def initialize(msg = "Hello, world!")
      @msg = msg
    end
    def say
      @msg.freeze
    end
  end
  
  module Multiplier
    spec "helper should return x*x" do
      helper(0).should == 0
      helper(1).should == 1
      helper(2).should == 4
      helper(2**32).should == 2**64
    end
    
    def helper(x)
      x * x
    end
  end
end

if __FILE__ == $0
  Literate.run.each do |result|
    puts result
  end
end
