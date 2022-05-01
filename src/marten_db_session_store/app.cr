require "./models/**"
require "./store"

# Registers the DB session store.
Marten::HTTP::Session::Store.register("db", MartenDBSessionStore::Store)

module MartenDBSessionStore
  class App < Marten::App
    label "marten_db_session_store"
  end
end
