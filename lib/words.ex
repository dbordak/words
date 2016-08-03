defmodule Words do
  use Application

  @id_length Application.get_env(:words, :id_length)

  def generate_player_id do
    @id_length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Words.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Words.Endpoint, []),
      # Start your own worker by calling: Words.Worker.start_link(arg1, arg2, arg3)
      # worker(Words.Worker, [arg1, arg2, arg3]),
      supervisor(Words.Game.Supervisor, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Words.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Words.Endpoint.config_change(changed, removed)
    :ok
  end
end
