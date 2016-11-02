# Words

Words is a clone of Codenames by Vlaada Chvatil, written in Elixir and Elm using Phoenix. It's functional enough to do complete games on, but suffers from a few major issues. Further, it is not a great example for how to organize code for either project -- it was a project I undertook to learn these technologies, so I was not acquainted with their best practices. With that said, I am content with the current version for the time being.

## Startup

What follows is the standard Phoenix setup guide:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
