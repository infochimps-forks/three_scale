require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/three_scale.rb'
#include ModelSpecHelper

describe ThreeScale::User do

  it "should find an existing user" do
    @user = ThreeScale::User.new("query_api_spec_test", :apikey => "query_api_spec_test69", :tier => "Baboon")
    @user.signup!
    ThreeScale::User.find("query_api_spec_test").should_not be_false
    @user.cancel!
  end

  describe "when creating a new user" do

    before(:each) do
      @user = ThreeScale::User.new("query_api_spec_test", :apikey => "query_api_spec_test69", :tier => "Baboon")
    end

    it "should signup a user" do
      @user.signup!.success?.should be_true
    end


    it "should use an existing user account if duplicate is found" do
      @user.signup!
      @user2 = ThreeScale::User.new("query_api_spec_test", :apikey => "query_api_spec_test269", :tier => "Silverback")
      resp = @user2.signup!
      resp.success?.should be_true
    end

    after(:each) do
      @user.cancel! if @user.has_account?
      @user = nil
    end

  end

  describe "when managing a user account" do

    before(:each) do
      @user = ThreeScale::User.new("query_api_spec_test", :apikey => "query_api_spec_test69", :tier => "Baboon")
      @user.signup!
    end

    it "should generate a new apikey when none is given" do
      apikey = @user.apikey
      @user.regenerate_apikey!
      @user.apikey.should_not == apikey
    end

    it "should register as an existing account" do
      @user.has_account?.should be_true
    end

    it "should use a given apikey to update" do
      @user.regenerate_apikey!("foobar69")
      @user.apikey.should == "foobar69"
    end

    it "should switch tiers" do
      tier = @user.tier
      @user.tier = "Brass Monkey"
      @user.update!.success?.should be_true
      tier.should_not == @user.tier
    end

    it "should update user details" do
      @user.first_name = "Billy"
      @user.last_name = "theKidd"
      @user.email = "theKidd@gmail.com"

      @user.update!.success?.should be_true

      @user.first_name.should == "Billy"
      @user.last_name.should == "theKidd"
      @user.email.should == "theKidd@gmail.com"
    end

    it "should cancel an account" do
      @user.cancel!.success?.should be_true
      @user.has_account?.should be_false
    end

    after(:each) do
      @user.cancel! if @user.has_account?
      @user = nil
    end

  end

end
