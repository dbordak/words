# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :words,
  ecto_repos: [Words.Repo]

# Configures the endpoint
config :words, Words.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ecW7DXJB04BsbyHxnRaOitUWwkT0r216+mKKjsifVDKLZqDqXqw2b68GVxrt1zlz",
  render_errors: [view: Words.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Words.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
