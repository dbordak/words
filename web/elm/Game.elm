module Game exposing (..) --where

import Html exposing (Html, h3, h4, div, text, ul, li, input, form, button, br, table, tbody, tr, td, span, label, article, header, section, footer)
import Html.Attributes exposing (type', value, placeholder, disabled, name, for, id, class, classList, checked)
import Html.Events exposing (onInput, onSubmit, onClick, onCheck)
import Dict

import Routes
import Models exposing (..)

view : Model -> Html Msg
view model =
  div [ id "game-container", class ("team-" ++ model.playerInfo.team )]
    [ hintDisplay model.hint
    , boardTable model
    , touchButtons model
    , voteButton model
    , hintInput model
    , gameOverModal model]

hintDisplay : Maybe Hint -> Html Msg
hintDisplay mHint =
  case mHint of
    Just hint ->
      h3 [ class ("hint-" ++ hint.team), id "hint-display"]
        [text ("Current hint: " ++ hint.word ++ ", " ++ (toString hint.count) ++ " (Remaining: " ++ (toString (hint.remaining + 1)) ++ ")")]
    Nothing ->
      h3 [ id "hint-display" ]
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
  ul [ id "word-list" ]
    (List.map (boardCell model) model.board)

boardCell : Model -> String -> Html Msg
boardCell model cell =
  let
    wordStats = case Dict.get cell model.wordMap of
                  Nothing ->
                    {color = "u", touched = True}
                  Just val ->
                    val
  in
    li []
      [input [type' "radio", name "board", value cell, id cell,
                 onCheck (\_ -> SetActiveWord cell),
                 disabled (model.playerInfo.can_hint || wordStats.touched)] []
      , label [for cell, classList [
                  ("toggle", True),
                  ("button", True),
                  ("word-label", True),
                  ("color-" ++ wordStats.color, True),
                  ("touched", wordStats.touched)]]
        [text cell]]

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
