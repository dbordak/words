defmodule Words.Game.Dictionary do
  @words [
    "stone",
    "Egypt",
    "England",
    "Japan",
    "Switzerland",
    "Canary Islands",
    #"the world",
    "aura",
    "wagon",
    "speed",
    "star",
    "rainbow",
    "diver",
    "coffin",
    "F-Zero",
    "punch",
    "fist",
    "muscles",
    "vampire",
    "breads",
    "steamroller",
    "hands",
    "zombie",
    "pillar",
    "sun",
    "awaken",
    "7-Up"

    # adjectives don't work too well
    # "dark",
    # "holy",
  ]

  def get_words(num) do
    words = @words |> Enum.shuffle |> Enum.take(num)
  end
end
