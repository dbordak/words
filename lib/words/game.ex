defmodule Words.Game do
  @moduledoc """
  Game server
  """

  use GenServer
  #require Logger

  defstruct [
    id: nil,
    blue_leader: nil,
    red_leader: nil,
    beeples: [],
    over: false,
    winner: nil
  ]

  # Client

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: ref(id))
  end

  def join(id, player_id, pid), do: try_call(id, {:join, player_id, pid})

  # Server
  def get_data(id), do: try_call(id, :get_data)

  def init(id) do
    {:ok, %__MODULE__ {id: id}}
  end

  def handle_call({:join, player_id, pid}, _from, game) do
    cond do
      Enum.member?([game.blue_leader, game.red_leader | game.beeples], player_id) ->
        {:reply, {:ok, self}, game}
      true ->
        Process.flag(:trap_exit, true)
        Process.monitor(pid)

        game = add_player(game, player_id)

        {:reply, {:ok, self}, game}
    end
  end

  def handle_call(:get_data, _from, game), do: {:reply, game, game}
  def handle_call({:get_data, player_id}, _from, game) do
    nil
  end

  defp create_board(game_id), do: Words.Game.Board.create(game_id)

  defp add_player(%__MODULE__{blue_leader: nil} = game, player_id) do
    {:ok, board_pid} = create_board(game.id)
    Process.monitor(board_pid)
    %{game | blue_leader: player_id}
  end
  defp add_player(%__MODULE__{red_leader: nil} = game, player_id), do: %{game | red_leader: player_id}
  defp add_player(game, player_id), do: %{game | beeples: game.beeples ++ [player_id]}

  defp ref(id), do: {:global, {:game, id}}

  defp try_call(id, message) do
    case GenServer.whereis(ref(id)) do
      nil ->
        {:error, "Game does not exist"}
      game ->
        GenServer.call(game, message)
    end
  end
end
