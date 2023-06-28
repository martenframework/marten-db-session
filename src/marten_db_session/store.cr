module MartenDBSession
  # Database session store.
  class Store < Marten::HTTP::Session::Store::Base
    @entry : Entry? = nil

    def create : Nil
      @session_key = gen_session_key
      persist_session_data

      @modified = true
    end

    def flush : Nil
      Entry.get(key: @session_key.not_nil!).try(&.delete) unless @session_key.nil?

      @entry = nil
      @session_hash = SessionHash.new
      @session_key = nil
      @modified = true
    end

    def load : SessionHash
      @entry = Entry.get!(key: @session_key.not_nil!, expires__gt: Time.local(Marten.settings.time_zone))
      SessionHash.from_json(entry!.data!)
    rescue Marten::DB::Errors::RecordNotFound | NilAssertionError
      create
      SessionHash.new
    end

    def save : Nil
      @modified = true
      persist_session_data(session_hash)
    end

    def clear_expired_entries : Nil
      Entry.filter(expires__lt: Time.local(Marten.settings.time_zone)).delete
    end

    private getter entry

    private def entry!
      entry.not_nil!
    end

    private def gen_session_key
      Random::Secure.random_bytes(16).hexstring
    end

    private def persist_session_data(data = nil)
      data = data.nil? ? "{}" : data.to_json
      expires = Time.local(Marten.settings.time_zone) + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age)

      if @entry.nil?
        @entry = Entry.create!(key: @session_key.not_nil!, data: data, expires: expires)
      else
        entry!.data = data
        entry!.expires = expires
        entry!.save!
      end
    end
  end
end
