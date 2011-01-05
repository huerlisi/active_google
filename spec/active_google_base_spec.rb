require 'spec_helper'

describe ActiveGoogle::Base do
  it "should be valid" do
    ActiveGoogle::Base.should be_a(Class)
  end
end
