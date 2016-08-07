module Game exposing (..) --where

import Html exposing (Html, h3, h4, div, text, ul, li, input, form, button, br, table, tbody, tr, td, span, label)
import Html.Attributes exposing (type', value, placeholder, disabled, name, for, id, class, classList)
import Html.Events exposing (onInput, onSubmit, onClick, onCheck)
import Dict

import Routes
import Models exposing (..)

view : Model -> Html Msg
view model =
  div []
    [ h3 [] [ text model.playerStatus ]
    , boardTable model
    , touchButtons model
    , voteButton model
    , hintDisplay model.hint
    , hintInput model]

hintDisplay : Hint -> Html Msg
hintDisplay hint =
  h4 [ class ("hint-" ++ hint.team)] [text ("Current hint: " ++ hint.word ++ ", " ++ (toString hint.count))]

hintInput: Model -> Html Msg
hintInput model =
  if model.playerInfo.can_hint then
    div []
      [ input [ placeholder "Hint", type' "text", value model.newHint.word, onInput SetNewHintWord ] []
      , input [ placeholder "Count", type' "number", onInput SetNewHintCount ] []
      , button [ disabled (model.turn /= model.playerInfo.team), onClick SendNewHint ] [ text "Submit" ]]
  else
    text ""

touchButtons : Model -> Html Msg
touchButtons model =
  if model.playerInfo.can_touch then
    div []
      [ button [ disabled (model.turn /= model.playerInfo.team), onClick TouchWord ] [ text "Touch" ]
      , button [ disabled (model.turn /= model.playerInfo.team), onClick PassTurn ] [ text "Pass" ]]
  else
    text ""

voteButton : Model -> Html Msg
voteButton model =
  if model.playerInfo.can_vote then
    button [] [text "Cast Vote"]
  else
    text ""

boardTable : Model -> Html Msg
boardTable model =
  table []
    [ tbody [] (List.map (\row -> tr []
                            (List.map (boardCell model) row)) model.board) ]

boardCell : Model -> String -> Html Msg
boardCell model cell =
  let
    wordStats = case Dict.get cell model.wordMap of
                  Nothing ->
                    {color = "u", touched = True}
                  Just val ->
                    val
  in
    td []
      [input [type' "radio", name "board", value cell, id cell,
                 onCheck (\_ -> SetActiveWord cell),
                 disabled (model.playerInfo.can_hint || wordStats.touched)] []
      , label [for cell, classList [
                  ("word-label", True),
                  ("color-" ++ wordStats.color, True),
                  ("touched", wordStats.touched)]]
        [text cell]]
