# Marten DB Session Store

**Marten DB Session Store** is a database session store for the Marten web framework. 

## Installation

Simply add the following entry to your project's `shard.yml`:

```yaml
dependencies:
  marten_db_session_store:
    github: martenframework/marten-db-session-store
```

And run `shards install` afterwards.

Once installed you can configure your project to use the database session store by following these steps:

First, add the `MartenDBSessionStore::App` app class to your project's `installed_apps` setting and ensure that your `sessions.store` setting is set to `:db`:

```crystal
Marten.configure do |config|
  # Other settings...

  config.installed_apps = [
    MartenDBSessionStore::App,
    # Other apps..
  ]

  config.sessions.store = :db
end
```

Then run the `marten migrate` command in order to install the DB session entry model.

_Congrats! You’re in!_ From now on, your session data will be persisted in a `marten_db_session_store_entry` table.

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and 
[contributors](https://github.com/martenframework/marten/contributors).

## License

MIT. See ``LICENSE`` for more details.
