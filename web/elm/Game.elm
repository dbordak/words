module Game exposing (..) --where

import Html exposing (Html, h1, h3, div, text, input, button, span, label, article, header, section, footer)
import Html.Attributes exposing (type', value, placeholder, disabled, name, for, id, class, classList, checked)
import Html.Events exposing (onInput, onSubmit, onClick, onCheck)
import Dict

import Routes
import Models exposing (..)

view : Model -> Html Msg
view model =
  div [ id "game-container", class ("team-" ++ model.playerInfo.team )]
    [ topBar model
    , boardTable model
    , touchButtons model
    , voteButton model
    , hintInput model
    , gameOverScreen model]

topBar : Model -> Html Msg
topBar model =
  div [ id "top-bar" ]
    [ settingsModal model
    , hintDisplay model.hint
    , helpModal model
    ]

hintDisplay : Maybe Hint -> Html Msg
hintDisplay mHint =
  case mHint of
    Just hint ->
      label [ class ("hint-" ++ hint.team), id "hint-display"]
        [text ("Current hint: " ++ hint.word ++ ", " ++ (toString hint.count) ++ " (Remaining: " ++ (toString (hint.remaining + 1)) ++ ")")]
    Nothing ->
      label [ id "hint-display" ]
        [ text "No current hint."]

hintInput: Model -> Html Msg
hintInput model =
  if model.playerInfo.can_hint then
    div [ id "hint-input" ]
      [ input [ placeholder "Hint", id "hint-word", type' "text", value model.newHint.word, onInput SetNewHintWord ] []
      , input [ placeholder "Count", id "hint-count", type' "number", onInput SetNewHintCount ] []
      , button [ class "game-button", disabled (model.turn /= model.playerInfo.team), onClick SendNewHint ] [ text "Submit" ]]
  else
    text ""

touchButtons : Model -> Html Msg
touchButtons model =
  if model.playerInfo.can_touch then
    div [ id "touch-buttons" ]
      [ button [ class "game-button", disabled (model.turn /= model.playerInfo.team), onClick TouchWord ] [ text "Touch" ]
      , button [ class "game-button", disabled (model.turn /= model.playerInfo.team), onClick PassTurn ] [ text "Pass" ]]
  else
    text ""

voteButton : Model -> Html Msg
voteButton model =
  if model.playerInfo.can_vote then
    button [ class "game-button" ] [text "Cast Vote"]
  else
    text ""

boardTable : Model -> Html Msg
boardTable model =
  div [ id "word-list" ]
    (List.map (boardCell model) model.words)

boardCell : Model -> String -> Html Msg
boardCell model cell =
  let
    wordStats = case Dict.get cell model.wordMap of
                  Nothing ->
                    {color = "u", touched = True}
                  Just val ->
                    val
  in
    label []
      [ input [type' "radio", name "board", value cell,
               onCheck (\_ -> SetActiveWord cell),
               disabled (model.playerInfo.can_hint || wordStats.touched)] []
      , span [classList [
              ("toggle", True),
              ("button", True),
              ("word-label", True),
              ("color-" ++ wordStats.color, True),
              ("touched", wordStats.touched)]]
        [text cell]]

helpModal : Model -> Html Msg
helpModal model =
  div []
    [ label [ for "help-modal", class "button" ] [ text "butt2"]
    , div [class "modal"]
      [ input [type' "checkbox", id "help-modal", checked False] []
      , label [for "help-modal", class "overlay"] []
      , article []
        [ header []
            [ h3 [] [text "Help"] ]
        , section [class "content"] [ text "TODO"]
        , footer []
          [ label [for "help-modal", class "button game-button"] [text "Ok"]]]]]

settingsModal : Model -> Html Msg
settingsModal model =
  div []
    [ label [ for "settings-modal", class "button" ] [ text "butt1" ]
    , div [class "modal"]
      [ input [type' "checkbox", id "settings-modal", checked False] []
      , label [for "settings-modal", class "overlay"] []
      , article []
        [ header []
            [ h3 [] [text "Settings"] ]
        , section [class "content"] [ text "TODO"]
        , footer []
          [ label [for "settings-modal", class "button game-button"] [text "Ok"]]]]]

gameOverModal : Model -> Html Msg
gameOverModal model =
  case model.winner of
    Nothing ->
      text ""
    Just winner ->
      div [class "modal"]
        [ input [type' "checkbox", id "game-over-modal", checked True] []
        , label [for "game-over-modal", class "overlay"] []
        , article []
          [ header []
              [ h3 [] [text "Game Over"] ]
          , section [class "content"] [ text (winner ++ " wins!")]
          , footer []
            [ label [for "game-over-modal", class "button game-button"] [text "Ok"]]]]

gameOverScreen : Model -> Html Msg
gameOverScreen model =
  case model.winner of
    Nothing ->
      text ""
    Just winner ->
      div [ id "game-over" ]
        [ input [type' "checkbox", id "game-over-screen", checked True] []
        , label [for "game-over-screen", class "overlay"] []
        , div [class "message"]
          [ h1 [] [text "GAME OVER"]
          , h3 [] [text (winner ++ " team wins")]]
        ]
