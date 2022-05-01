require "./spec_helper"

describe DBSessionStore::Store do
  describe "#create" do
    it "creates a new session entry without data" do
      store = DBSessionStore::Store.new(nil)
      store.create

      DBSessionStore::Entry.all.size.should eq 1
      entry = DBSessionStore::Entry.first!
      entry.data.should eq "{}"
    end

    it "creates a new session entry with the right expiry date" do
      store = DBSessionStore::Store.new(nil)

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store.create
      end

      DBSessionStore::Entry.all.size.should eq 1
      entry = DBSessionStore::Entry.first!
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
    end

    it "properly sets a new session key" do
      store = DBSessionStore::Store.new(nil)
      store.create

      store.session_key.not_nil!.size.should eq 32

      DBSessionStore::Entry.all.size.should eq 1
      entry = DBSessionStore::Entry.first!
      entry.key.should eq store.session_key
    end

    it "marks the store as modified" do
      store = DBSessionStore::Store.new(nil)
      store.create
      store.modified?.should be_true
    end
  end

  describe "#flush" do
    it "destroys the entry associated with the store session key if it exists" do
      DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: "{}"
      )

      store = DBSessionStore::Store.new("testkey")
      store.flush

      DBSessionStore::Entry.all.exists?.should be_false
    end

    it "completes successfully if no entry exists for the store session key" do
      DBSessionStore::Entry.create!(
        key: "otherkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: "{}"
      )

      store = DBSessionStore::Store.new("testkey")
      store.flush

      DBSessionStore::Entry.all.exists?.should be_true
    end

    it "marks the store as modified" do
      DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: "{}"
      )

      store = DBSessionStore::Store.new("testkey")
      store.flush

      store.modified?.should be_true
    end

    it "resets the store session key" do
      store = DBSessionStore::Store.new("testkey")
      store.flush

      store.session_key.should be_nil
    end

    it "resets the store session hash" do
      DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: {"foo": "bar"}.to_json
      )

      store = DBSessionStore::Store.new("testkey")
      store.flush

      store.empty?.should be_true
      store["foo"]?.should be_nil
    end
  end

  describe "#load" do
    it "retrieves the session entry record and loads the session hash from its data" do
      DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: {"foo": "bar"}.to_json
      )

      store = DBSessionStore::Store.new("testkey")
      store.load

      store["foo"].should eq "bar"
    end

    it "does not load the session hash if the session entry is expired" do
      DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local - Time::Span.new(seconds: 60),
        data: {"foo": "bar"}.to_json
      )

      store = DBSessionStore::Store.new("testkey")
      store.load

      store.empty?.should be_true
      store["foo"]?.should be_nil
    end

    it "does not load the session hash if the session entry does not exist" do
      store = DBSessionStore::Store.new("testkey")
      store.load

      store.empty?.should be_true
    end

    it "resets the session key if the session entry cannot be loaded because it is expired" do
      DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local - Time::Span.new(seconds: 60),
        data: {"foo": "bar"}.to_json
      )

      store = DBSessionStore::Store.new("testkey")
      store.load

      store.session_key.should_not eq "testkey"
    end

    it "resets the session key if the store was initialized without a session key" do
      store = DBSessionStore::Store.new(nil)
      store.load

      store.session_key.should_not be_nil
    end

    it "marks the store as modified if it was initialized without a session key" do
      store = DBSessionStore::Store.new(nil)
      store.load

      store.modified?.should be_true
    end
  end

  describe "#save" do
    it "persists the session data as expected if no entry was created before" do
      store = DBSessionStore::Store.new(nil)

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store["foo"] = "bar"
        store.save
      end

      DBSessionStore::Entry.all.size.should eq 1
      entry = DBSessionStore::Entry.first!
      entry.key!.size.should eq 32
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
      entry.data.should eq(
        {"foo" => "bar"}.to_json
      )
    end

    it "persists the session as expected if no entry was created before and the session hash is empty" do
      store = DBSessionStore::Store.new(nil)

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store.save
      end

      DBSessionStore::Entry.all.size.should eq 1
      entry = DBSessionStore::Entry.first!
      entry.key!.size.should eq 32
      entry.expires!.at_beginning_of_second.should eq(
        (time + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)).at_beginning_of_second
      )
      entry.data.should eq "{}"
    end

    it "persists the session data as expected if an entry was created before and updates the expiry time" do
      entry = DBSessionStore::Entry.create!(
        key: "testkey",
        expires: Time.local + Time::Span.new(hours: 48),
        data: {"foo" => "bar"}.to_json
      )

      store = DBSessionStore::Store.new("testkey")

      time = Time.local(Marten.settings.time_zone)
      Timecop.freeze(time) do
        store["test"] = "xyz"
        store.save
      end

      DBSessionStore::Entry.all.size.should eq 1

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
