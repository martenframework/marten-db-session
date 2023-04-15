# Marten DB Session

[![Version](https://img.shields.io/github/v/tag/martenframework/marten-db-session)](https://github.com/martenframework/marten-db-session/tags)
[![License](https://img.shields.io/github/license/martenframework/marten-db-session)](https://github.com/martenframework/marten-db-session/blob/main/LICENSE)
[![CI](https://github.com/martenframework/marten-db-session/workflows/Specs/badge.svg)](https://github.com/martenframework/marten-db-session/actions)
[![CI](https://github.com/martenframework/marten-db-session/workflows/QA/badge.svg)](https://github.com/martenframework/marten-db-session/actions)

**Marten DB Session** is a database [session store](https://martenframework.com/docs/handlers-and-http/sessions#session-stores) for the Marten web framework. 

## Installation

Simply add the following entry to your project's `shard.yml`:

```yaml
dependencies:
  marten_db_session:
    github: martenframework/marten-db-session
```

And run `shards install` afterward.

Once installed you can configure your project to use the database session store by following these steps:

First, add the following requirement to your project's `src/project.cr` file:

```crystal
require "marten_db_session"
```

Secondly, add the following requirement to the top-level `manage.cr` file in order to make Marten DB Session Store migrations available to your project:

```crystal
require "marten_db_session/cli"
```

Then, add the `MartenDBSession::App` app class to your project's `installed_apps` setting and ensure that your `sessions.store` setting is set to `:db`:

```crystal
Marten.configure do |config|
  # Other settings...

  config.installed_apps = [
    MartenDBSession::App,
    # Other apps..
  ]

  config.sessions.store = :db
end
```

Finally, run the `marten migrate` command in order to install the DB session entry model.

_Congrats! You’re in!_ From now on, your session data will be persisted in a `marten_db_session_store_entry` table.

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and 
[contributors](https://github.com/martenframework/marten-db-session/contributors).

## License

MIT. See ``LICENSE`` for more details.
