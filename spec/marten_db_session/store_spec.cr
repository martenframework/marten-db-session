require "./spec_helper"

describe MartenDBSession::Store do
  describe "#create" do
    it "creates a new session entry without data" do
      store = MartenDBSession::Store.new(nil)
      store.create

      MartenDBSession::Entry.all.size.should eq 1
      entry = MartenDBSession::Entry.first!
      entry.data.should eq "{}"
    end

    it "creates a new session entry with the right expiry date" do
      store = MartenDBSession::Store.new(nil)

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store.create
      end

      MartenDBSession::Entry.all.size.should eq 1
      entry = MartenDBSession::Entry.first!
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
    end

    it "properly sets a new session key" do
      store = MartenDBSession::Store.new(nil)
      store.create

      store.session_key.not_nil!.size.should eq 32

      MartenDBSession::Entry.all.size.should eq 1
      entry = MartenDBSession::Entry.first!
      entry.key.should eq store.session_key
    end

    it "marks the store as modified" do
      store = MartenDBSession::Store.new(nil)
      store.create
      store.modified?.should be_true
    end
  end

  describe "#flush" do
    it "destroys the entry associated with the store session key if it exists" do
      MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: "{}"
      )

      store = MartenDBSession::Store.new("testkey")
      store.flush

      MartenDBSession::Entry.all.exists?.should be_false
    end

    it "completes successfully if no entry exists for the store session key" do
      MartenDBSession::Entry.create!(
        key: "otherkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: "{}"
      )

      store = MartenDBSession::Store.new("testkey")
      store.flush

      MartenDBSession::Entry.all.exists?.should be_true
    end

    it "marks the store as modified" do
      MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: "{}"
      )

      store = MartenDBSession::Store.new("testkey")
      store.flush

      store.modified?.should be_true
    end

    it "resets the store session key" do
      store = MartenDBSession::Store.new("testkey")
      store.flush

      store.session_key.should be_nil
    end

    it "resets the store session hash" do
      MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: {"foo": "bar"}.to_json
      )

      store = MartenDBSession::Store.new("testkey")
      store.flush

      store.empty?.should be_true
      store["foo"]?.should be_nil
    end
  end

  describe "#load" do
    it "retrieves the session entry record and loads the session hash from its data" do
      MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: {"foo": "bar"}.to_json
      )

      store = MartenDBSession::Store.new("testkey")
      store.load

      store["foo"].should eq "bar"
    end

    it "does not load the session hash if the session entry is expired" do
      MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local(Marten.settings.time_zone) - Time::Span.new(seconds: 60),
        data: {"foo": "bar"}.to_json
      )

      store = MartenDBSession::Store.new("testkey")
      store.load

      store.size.should eq 0
      store["foo"]?.should be_nil
    end

    it "does not load the session hash if the session entry does not exist" do
      store = MartenDBSession::Store.new("testkey")
      store.load

      store.size.should eq 0
    end

    it "resets the session key if the session entry cannot be loaded because it is expired" do
      MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local - Time::Span.new(seconds: 60),
        data: {"foo": "bar"}.to_json
      )

      store = MartenDBSession::Store.new("testkey")
      store.load

      store.session_key.should_not eq "testkey"
    end

    it "resets the session key if the store was initialized without a session key" do
      store = MartenDBSession::Store.new(nil)
      store.load

      store.session_key.should_not be_nil
    end

    it "marks the store as modified if it was initialized without a session key" do
      store = MartenDBSession::Store.new(nil)
      store.load

      store.modified?.should be_true
    end
  end

  describe "#save" do
    it "persists the session data as expected if no entry was created before" do
      store = MartenDBSession::Store.new(nil)

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store["foo"] = "bar"
        store.save
      end

      MartenDBSession::Entry.all.size.should eq 1
      entry = MartenDBSession::Entry.first!
      entry.key!.size.should eq 32
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
      entry.data.should eq(
        {"foo" => "bar"}.to_json
      )
    end

    it "persists the session as expected if no entry was created before and the session hash is empty" do
      store = MartenDBSession::Store.new(nil)

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store.save
      end

      MartenDBSession::Entry.all.size.should eq 1
      entry = MartenDBSession::Entry.first!
      entry.key!.size.should eq 32
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
      entry.data.should eq "{}"
    end

    it "persists the session data as expected if an entry was created before and updates the expiry time" do
      entry = MartenDBSession::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: {"foo" => "bar"}.to_json
      )

      store = MartenDBSession::Store.new("testkey")

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store["test"] = "xyz"
        store.save
      end

      MartenDBSession::Entry.all.size.should eq 1

      entry.reload
      entry.key.should eq "testkey"
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
      entry.data.should eq(
        {"foo" => "bar", "test" => "xyz"}.to_json
      )
    end
  end
end
