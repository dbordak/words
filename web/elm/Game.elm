module Game exposing (..) --where

import Html exposing (Html, h3, div, text, ul, li, input, form, button, br, table, tbody, tr, td, span, label)
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
    , div [] [ button [ onClick TouchWord ] [text "Cast"]
             , button [] [text "Pass"]]]

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
                 disabled ((not model.enableButtons) || wordStats.touched)] []
      , label [for cell, classList [
                  ("word-label", True),
                  ("color-" ++ wordStats.color, True),
                  ("touched", wordStats.touched)]]
        [text cell]]
