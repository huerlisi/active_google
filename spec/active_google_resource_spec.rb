require 'spec_helper'

class Contact < ActiveGoogle::Resource
end

describe ActiveGoogle::Resource do
  describe ".element_path" do
    it "should use the google contacts api path" do
      Contact.element_path(1).should == "/m8/feeds/contacts/default/base/1"
    end
  end

  describe ".collection_path" do
    it "should use the google contacts api path" do
      Contact.collection_path.should == "/m8/feeds/contacts/default/full"
    end
  end
end
