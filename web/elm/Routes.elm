module Routes exposing (..)

import String
import UrlParser exposing ((</>))
import Navigation

type Page = Lobby | Game String

-- URL PARSING

toUrl : Page -> String
toUrl page =
  case page of
    Lobby ->
      "#"
    Game gameId ->
      "#game/" ++ gameId

pageParser : UrlParser.Parser (Page -> a) a
pageParser =
  UrlParser.oneOf
    [ UrlParser.format Game (UrlParser.s "game" </> UrlParser.string)
    , UrlParser.format Lobby (UrlParser.s "")]

urlParser : Navigation.Location -> Result String Page
urlParser location =
  UrlParser.parse identity pageParser (String.dropLeft 1 location.hash)

pageChannel : Page -> String
pageChannel page =
  case page of
    Lobby ->
      "lobby"
    Game gameId ->
      "game:" ++ gameId
