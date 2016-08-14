defmodule Words.Game.Board do
  defmodule Space do
    defstruct [
      color: nil,
      touched: false
    ]
  end
  @num_words 25
  @num_team_spaces 8
  @num_ded 1

  @grid_value_blue "b"
  @grid_value_red "r"
  @grid_value_neutral "n"
  @grid_value_ded "x"
  @grid_value_unknown "u"

  defstruct [
    game_id: nil,
    word_map: %{},
    first_team: nil
  ]

  def create(game_id) do
    first_team = :blue
    words = Words.Game.Dictionary.get_words(@num_words)
    word_map = build_word_map(words, first_team)

    Agent.start(fn -> %__MODULE__{game_id: game_id, word_map: word_map,
                                  first_team: first_team} end,
      name: ref(game_id))
  end

  def get_data(game_id) do
    Agent.get(ref(game_id), &(&1))
  end

  def public_word_map(word_map) do
    Enum.map(word_map, fn {word, space} -> {word, hide_space(space)} end)
    |> Enum.into(%{})
  end

  def only_touched(word_map) do
    Enum.filter(word_map, fn {word, space} -> space.touched end)
    |> Enum.into(%{})
  end

  defp hide_space(space) do
    if space.touched do
      space
    else
      %{space | color: @grid_value_unknown}
    end
  end

  def all_touched?(word_map, color) do
    word_map
    |> Enum.filter(fn {_, data} -> data.color == color end)
    |> Enum.all?(fn {_, data} -> data.touched end)
  end

  def touch_word(game_id, player_id, word) do
    board = get_data(game_id)

    cond do
      board.word_map[word].touched ->
        {:error, "Word is already touched."}
      word == "" ->
        {:error, "No word provided."}
      Words.Game.can_touch_word?(game_id, player_id) ->
        new_word_map = %{board.word_map | word =>
                          %{board.word_map[word] | touched: true}}
        winner = cond do
          board.word_map[word].color == @grid_value_ded ->
            if Words.Game.on_red_team?(game_id, player_id) do
              :blue
            else
              :red
            end
          board.word_map[word].color == @grid_value_blue ->
            if all_touched?(board.word_map, @grid_value_blue) do
              :blue
            else
              false
            end
          board.word_map[word].color == @grid_value_red ->
            if all_touched?(board.word_map, @grid_value_red) do
              :red
            else
              false
            end
          true ->
            false
        end
        cond do
          winner ->
            Words.Game.set_winner(game_id, winner)
          board.word_map[word].color == @grid_value_red && Words.Game.on_red_team?(game_id, player_id) ->
            Words.Game.dec_hint(game_id)
          board.word_map[word].color == @grid_value_blue && Words.Game.on_blue_team?(game_id, player_id) ->
            Words.Game.dec_hint(game_id)
          true ->
            Words.Game.next_turn(game_id)
        end
        Agent.update(ref(game_id), fn(_) -> %{board | word_map: new_word_map} end)

        {:ok, new_word_map}
      true ->
        {:error, "Player is not a fingerman."}
    end
  end

  defp build_word_map(words, first_team) do
    num_neutral = @num_words - @num_ded - @num_team_spaces*2 - 1
    extra_color = cond do
      first_team == :blue ->
        @grid_value_blue
      first_team == :red ->
        @grid_value_red
    end
    colors = List.duplicate(@grid_value_ded, @num_ded) ++
      List.duplicate(@grid_value_blue, @num_team_spaces) ++
      List.duplicate(@grid_value_red, @num_team_spaces) ++
      List.duplicate(@grid_value_neutral, num_neutral) ++
      [extra_color]
      |> Enum.shuffle
      |> Enum.map(fn x -> %Space{color: x} end)

    Enum.zip(words, colors)
    |> Enum.into(%{})
  end

  defp ref(game_id), do: {:global, {:board, game_id}}
end
