defmodule Words.GameChannel do
  use Phoenix.Channel
  alias Words.Game

  def join("game:" <> game_id, _message, socket) do
    player_id = socket.assigns.player_id

    case Game.join(game_id, player_id, socket.channel_pid) do
      {:ok, _pid} ->
        {:ok, assign(socket, :game_id, game_id)}
      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  def handle_in("game:joined", _message, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id
    board = Game.Board.get_data(game_id)
    game = Game.get_data(game_id)

    #TODO: can_chat
    can_hint = Game.can_give_hint?(game_id, player_id)
    team = cond do
      Words.Game.on_blue_team?(game_id, player_id) ->
        :blue
      Words.Game.on_red_team?(game_id, player_id) ->
        :red
    end

    word_map = if can_hint do
      board.word_map
    else
      Game.Board.public_word_map(board.word_map)
    end

    broadcast! socket, "game:player_joined", %{player_id: player_id}
    {:reply, {:ok, %{player_info: %{id: player_id,
                                    team: team,
                                    can_hint: can_hint,
                                    can_touch: Game.can_touch_word?(game_id, player_id),
                                    can_vote: Game.can_vote?(game_id, player_id)},
                     word_map: word_map,
                     turn: game.turn,
                     hint: game.hint}}, socket}
  end

  def handle_in("game:msg", msg, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    team = cond do
      Game.on_blue_team?(game_id, player_id) ->
        :blue
      Game.on_red_team?(game_id, player_id) ->
        :red
    end

    rank = cond do
      Game.can_give_hint?(game_id, player_id) ->
        :leader
      Game.can_touch_word?(game_id, player_id) ->
        :fingerman
      true ->
        :voter
    end

    broadcast socket, "game:msg", %{user: player_id, body: msg["body"], team: team, rank: rank}
    {:reply, {:ok, %{msg: msg["body"]}}, socket}
  end

  def handle_in("game:touch", %{"word" => word}, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    case Words.Game.is_phase_and_turn(game_id, player_id) do
      {:ok, _} ->
        case Game.Board.touch_word(game_id, player_id, word) do
          {:ok, new_word_map} ->
            word_map_diff = Game.Board.only_touched(new_word_map)
            game = Game.get_data(game_id)
            if game.over do
              broadcast(socket, "game:over", %{winner: game.winner})
            end
			broadcast(socket, "game:touch", %{word_map: word_map_diff, turn: game.turn})
            broadcast(socket, "game:hint", game.hint)
            {:noreply, socket}
          {:error, reason} ->
            {:reply, {:error, %{reason: reason}}, socket}
        end
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("game:pass", _message, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id
    game = Words.Game.get_data(game_id)

    case Words.Game.is_phase_and_turn(game_id, player_id) do
      {:ok, _} ->
        cond do
          Words.Game.can_touch_word?(game_id, player_id) ->
            Words.Game.next_turn(game_id)
            game = Words.Game.get_data(game_id)
            broadcast(socket, "game:touch", %{turn: game.turn})
            {:noreply, socket}
          true ->
            {:reply, {:error, %{reason: "Player is not a fingerman."}}, socket}
        end
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("game:hint", %{"word" => word, "count" => count}, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    case Words.Game.is_phase_and_turn(game_id, player_id) do
      {:ok, _} ->
        cond do
          Words.Game.can_give_hint?(game_id, player_id) ->
            team = cond do
              Words.Game.on_blue_team?(game_id, player_id) ->
                :blue
              Words.Game.on_red_team?(game_id, player_id) ->
                :red
            end
            Words.Game.next_phase(game_id)
			hint = %Words.Game.Hint{word: word, count: count, team: team, remaining: count}
			Words.Game.set_hint(game_id, hint)
            broadcast(socket, "game:hint", hint)
            {:noreply, socket}
          true ->
            {:reply, {:error, %{reason: "Player is not a leader."}}, socket}
        end
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end
end
