defmodule Words.Game.Dictionary do
  @words [
    # Jojo's
    "stone",
    "Egypt",
    "England",
    "Japan",
    "Switzerland",
    "Canary Islands",
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
    "7-Up",
    "platinum",
    "mask",
	"Italy",

    # Tarot
    "magician",
    # "high priestess",
    "empress",
    "emporer",
    "pope", # hierophant, pope, whatever
    # "lovers",
    "chariot",
    "strength",
    "hermit",
    # "wheel of fortune",
    "justice",
    # "hanged man",
    "death",
    # "temperance",
    # "devil",
    "tower",
    "moon",
    # "judgement",
    "world",
    "fool",

    # animals
    "frog",
    "gorilla",
    "orangutan",
    "donkey",
    "ogre",
    "roast beef",

    # memes
    "nut",
    "shack",
    "kebab",
    "trolley",
    "boy",
    "coconut",
    "gun"

    # adjectives don't work too well
    # "dark",
    # "holy",
  ]

  def get_words(num) do
    words = @words |> Enum.shuffle |> Enum.take(num)
  end
end
