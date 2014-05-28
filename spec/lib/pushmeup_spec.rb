require 'spec_helper'

describe Pushmeup do
  describe "APNS" do
    it "should have a APNS object" do
      APNS.should_not be_nil
    end

    it "should not forget the APNS default parameters" do
      APNS.host.should == "gateway.sandbox.push.apple.com"
      APNS.port.should == 2195
      APNS.pem_data.should be_equal(nil)
      APNS.pass.should be_equal(nil)
    end

    describe "Notifications" do

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = APNS::Notification.new("123", {:alert => "hi"})
          b = APNS::Notification.new("123", {:alert => "hi"})
          a.should eq(b)
        end

      end

    end

    describe "Packed Message" do
      it "should generate packed message with all params" do
        a = APNS::Notification.new("123", {alert: "hi", badge: "+1", sound: 'default', content_available: true})

        subject = a.packaged_message

        subject.should =~ /hi/
        subject.should =~ /\+1/
        subject.should =~ /default/
        subject.should =~ /true/
      end

      it "should generate packed message with other params" do
        a = APNS::Notification.new("123", {alert: "hi", other: { 'aps' => { 'extras' => { 'id' => '321' } } }})

        subject = a.packaged_message
        puts subject

        subject.should =~ /hi/
        subject.should =~ /extras/
        subject.should =~ /id/
        subject.should =~ /321/
      end
    end

  end

  describe "GCM" do
    it "should have a GCM object" do
      GCM.should_not be_nil
    end

    describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
      end

      it "should allow only notifications with device_tokens as array" do
        n = GCM::Notification.new("id", @options)
        n.device_tokens.is_a?(Array).should eq true

        n.device_tokens = ["a" "b", "c"]
        n.device_tokens.is_a?(Array).should eq true

        n.device_tokens = "a"
        n.device_tokens.is_a?(Array).should eq true
      end

      it "should allow only notifications with data as hash with :data root" do
        n = GCM::Notification.new("id", { :data => "data" })

        n.data.is_a?(Hash).should eq true
        n.data.should == {:data => "data"}

        n.data = {:a => ["a", "b", "c"]}
        n.data.is_a?(Hash).should eq true
        n.data.should == {:a => ["a", "b", "c"]}

        n.data = {:a => "a"}
        n.data.is_a?(Hash).should eq true
        n.data.should == {:a => "a"}
      end

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = GCM::Notification.new("id", { :data => "data" })
          b = GCM::Notification.new("id", { :data => "data" })
          a.should eq(b)
        end

      end

    end
  end
end
