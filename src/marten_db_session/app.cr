require "./models/**"
require "./store"

# Registers the DB session store.
Marten::HTTP::Session::Store.register("db", MartenDBSession::Store)

module MartenDBSession
  class App < Marten::App
    label "marten_db_session_store"
  end
end
