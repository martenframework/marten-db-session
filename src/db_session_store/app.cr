require "./models/**"
require "./store"

# Registers the DB session store.
Marten::HTTP::Session::Store.register("db", DBSessionStore::Store)

module DBSessionStore
  class App < Marten::App
    label "db_session_store"
  end
end
