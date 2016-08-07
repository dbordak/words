defmodule Words.Game do
  @moduledoc """
  Game server
  """

  use GenServer
  #require Logger

  defmodule Hint do
    defstruct [
      word: "",
      count: 0,
      team: nil
    ]
  end

  defmodule Team do
    defstruct [
      leader: nil,
      fingerman: nil,
      voters: []
    ]
  end

  defstruct [
    id: nil,
    blue_team: nil,
    red_team: nil,
    over: false,
    winner: nil,
    turn: :blue,
    phase: :hint,
    hint: nil
  ]

  # Client

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: ref(id))
  end

  def join(id, player_id, pid), do: try_call(id, {:join, player_id, pid})

  def set_winner(id, winner), do: try_call(id, {:set_winner, winner})

  def set_hint(id, hint), do: try_call(id, {:set_hint, hint})
  def dec_hint(id), do: try_call(id, :dec_hint)

  def next_turn(id), do: try_call(id, :next_turn)
  def next_phase(id), do: try_call(id, :next_phase)

  # Server
  def get_data(id), do: try_call(id, :get_data)

  def init(id) do
    {:ok, %__MODULE__ {id: id}}
  end

  def handle_call({:join, player_id, pid}, _from, game) do
    cond do
      on_team?(game.blue_team, player_id) || on_team?(game.red_team, player_id) ->
        {:reply, {:ok, self}, game}
      true ->
        Process.flag(:trap_exit, true)
        Process.monitor(pid)

        game = add_player(game, player_id)

        {:reply, {:ok, self}, game}
    end
  end

  def handle_call({:set_winner, winner}, _from, game) do
	{:reply, {:ok, self}, %{game | winner: winner, over: True}}
  end

  def handle_call({:set_hint, hint}, _from, game) do
	{:reply, {:ok, self}, %{game | hint: hint}}
  end

  def handle_call(:dec_hint, _from, game) do
    new_count = game.hint.count - 1
    if new_count < 0 do
      {:reply, {:ok, self}, _next_turn(game)}
    else
      {:reply, {:ok, self}, put_in(game.hint.count, new_count)}
    end
  end

  defp _next_turn(game) do
    new_turn = cond do
      game.turn == :blue -> :red
      game.turn == :red -> :blue
    end
    %{game | turn: new_turn, phase: :hint}
  end

  def handle_call(:next_turn, _from, game) do
    {:reply, {:ok, self}, _next_turn(game)}
  end

  def handle_call(:next_phase, _from, game) do
    new_phase = cond do
      game.phase == :hint -> :touch
      game.phase == :touch -> :hint
    end
    {:reply, {:ok, self}, %{game | phase: new_phase}}
  end

  def handle_call(:get_data, _from, game), do: {:reply, game, game}
  def handle_call({:get_data, player_id}, _from, game) do
    nil
  end

  def is_phase_and_turn(game_id, player_id) do
    case is_turn(game_id, player_id) do
      {:ok, _} ->
        is_phase(game_id, player_id)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def is_phase(game_id, player_id) do
    game = get_data(game_id)
    cond do
      can_give_hint?(game_id, player_id) && game.phase != :hint ->
        {:error, "It is not the hint phase."}
      can_touch_word?(game_id, player_id) && game.phase != :touch ->
        {:error, "It is not the touch phase."}
      true ->
        {:ok, nil}
    end
  end

  def is_turn(game_id, player_id) do
    game = get_data(game_id)
    cond do
      on_blue_team?(game_id, player_id) && game.turn != :blue ->
        {:error, "It is not blue's turn."}
      on_red_team?(game_id, player_id) && game.turn != :red ->
        {:error, "It is not red's turn."}
      true ->
        {:ok, nil}
    end
  end

  def can_touch_word?(game_id, player_id) do
    game = get_data(game_id)
    player_id == game.red_team.fingerman || player_id == game.blue_team.fingerman
  end

  def can_give_hint?(game_id, player_id) do
    game = get_data(game_id)
    player_id == game.red_team.leader || player_id == game.blue_team.leader
  end

  def can_vote?(game_id, player_id) do
    game = get_data(game_id)
    Enum.member?(game.red_team ++ game.blue_team, player_id)
  end

  def on_team?(team, player_id) do
    team != nil && (Enum.member?(team.voters, player_id) || player_id == team.leader || player_id == team.fingerman)
  end

  def on_blue_team?(game_id, player_id) do
    game = get_data(game_id)
    on_team?(game.blue_team, player_id)
  end

  def on_red_team?(game_id, player_id) do
    game = get_data(game_id)
    on_team?(game.red_team, player_id)
  end

  defp create_board(game_id), do: Words.Game.Board.create(game_id)

  defp add_player(%__MODULE__{blue_team: nil} = game, player_id) do
    {:ok, board_pid} = create_board(game.id)
    Process.monitor(board_pid)
    board = Words.Game.Board.get_data(game.id)
    %{game | blue_team: %Team{leader: player_id}, red_team: %Team{}, hint: %Hint{team: board.first_team}, turn: board.first_team}
  end
  defp add_player(%__MODULE__{red_team: %Team{leader: nil}} = game, player_id) do
    %{game | red_team: %__MODULE__.Team{leader: player_id}}
  end
  defp add_player(%__MODULE__{blue_team: %Team{fingerman: nil}} = game, player_id) do
    put_in game.blue_team.fingerman, player_id
  end
  defp add_player(%__MODULE__{red_team: %Team{fingerman: nil}} = game, player_id) do
    put_in game.red_team.fingerman, player_id
  end
  defp add_player(game, player_id) do
    if (length game.red_team.voters) < (length game.blue_team.voters) do
      put_in game.red_team.voters, (game.red_team.voters ++ [player_id])
    else
      put_in game.blue_team.voters, (game.blue_team.voters ++ [player_id])
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
