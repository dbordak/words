defmodule Words.Game do
  @moduledoc """
  Game server
  """

  use GenServer
  #require Logger

  defstruct [
    id: nil,
    blue_leader: nil,
    blue_fingerman: nil,
    blue_team: [],
    red_leader: nil,
    red_fingerman: nil,
    red_team: [],
    over: false,
    winner: nil,
    blue_turn: true
  ]

  # Client

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: ref(id))
  end

  def join(id, player_id, pid), do: try_call(id, {:join, player_id, pid})

  def next_turn(id), do: try_call(id, :next_turn)

  # Server
  def get_data(id), do: try_call(id, :get_data)

  def init(id) do
    {:ok, %__MODULE__ {id: id}}
  end

  def handle_call({:join, player_id, pid}, _from, game) do
    cond do
      Enum.member?([game.blue_leader, game.red_leader, game.blue_fingerman,
                     game.red_fingerman] ++ game.blue_team ++ game.red_team, player_id) ->
        {:reply, {:ok, self}, game}
      true ->
        Process.flag(:trap_exit, true)
        Process.monitor(pid)

        game = add_player(game, player_id)

        {:reply, {:ok, self}, game}
    end
  end

  def handle_call(:next_turn, _from, game) do
    {:reply, {:ok, self}, %{game | blue_turn: !game.blue_turn}}
  end

  def handle_call(:get_data, _from, game), do: {:reply, game, game}
  def handle_call({:get_data, player_id}, _from, game) do
    nil
  end

  def can_touch_word?(game_id, player_id) do
    game = get_data(game_id)
    player_id == game.red_fingerman || player_id == game.blue_fingerman
  end

  def can_vote?(game_id, player_id) do
    game = get_data(game_id)
    Enum.member?(game.red_team ++ game.blue_team, player_id)
  end

  def on_blue_team?(game_id, player_id) do
    game = get_data(game_id)
    Enum.member?(game.blue_team, player_id) || player_id == game.blue_leader || player_id == game.blue_fingerman
  end

  def on_red_team?(game_id, player_id) do
    not on_blue_team?(game_id, player_id)
  end

  defp create_board(game_id), do: Words.Game.Board.create(game_id)

  defp add_player(%__MODULE__{blue_leader: nil} = game, player_id) do
    {:ok, board_pid} = create_board(game.id)
    Process.monitor(board_pid)
    %{game | blue_leader: player_id}
  end
  defp add_player(%__MODULE__{red_leader: nil} = game, player_id), do: %{game | red_leader: player_id}
  defp add_player(%__MODULE__{blue_fingerman: nil} = game, player_id), do: %{game | blue_fingerman: player_id}
  defp add_player(%__MODULE__{red_fingerman: nil} = game, player_id), do: %{game | red_fingerman: player_id}
  defp add_player(game, player_id) do
    if (length game.red_team) < (length game.blue_team) do
      %{game | red_team: game.red_team ++ [player_id]}
    else
      %{game | blue_team: game.red_team ++ [player_id]}
    end
  end

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
