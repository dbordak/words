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
    player_status = cond do
      player_id == game.red_leader ->
        "red leader"
      player_id == game.blue_leader ->
        "blue leader"
      true ->
        "some schmo"
    end
    enable_buttons = !(player_id == game.red_leader || player_id == game.blue_leader)
    word_map = if enable_buttons do
      Game.Board.public_word_map(board.word_map)
    else
      board.word_map
    end

    broadcast! socket, "game:player_joined", %{player_id: player_id}
    {:reply, {:ok, %{board: board.grid,
                     player_status: player_status,
                     enable_buttons: enable_buttons,
                     word_map: word_map}}, socket}
  end

  def handle_in("game:touch", %{"word" => word}, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    case Game.Board.touch_word(game_id, player_id, word) do
      {:ok, new_word_map} ->
        public_word_map = Game.Board.public_word_map(new_word_map)

        broadcast(socket, "game:touch", %{word_map: public_word_map})
        {:noreply, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end
end
