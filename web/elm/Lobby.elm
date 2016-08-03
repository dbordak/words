module Lobby exposing (..) --where

import Html exposing (Html, h3, div, text, ul, li, input, form, button, br, table, tbody, tr, td)
import Html.Attributes exposing (type', value, placeholder)
import Html.Events exposing (onInput, onSubmit, onClick)
import Html.App
import Platform.Cmd
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing ((:=))
import Dict
import Navigation
import Models exposing (..)

view : Model -> Html Msg
view model =
  div []
    [ h3 [] [ text "Games:" ]
    , div
        []
        [ input [placeholder "Name", type' "text", value model.name, onInput SetName ] []
        , button [ onClick JoinNewGame ] [ text "New Game" ]
        ]
    , channelsTable (Dict.values model.phxSocket.channels)
    ]

channelsTable : List (Phoenix.Channel.Channel Msg) -> Html Msg
channelsTable channels =
  table []
    [ tbody [] (List.map channelRow channels)
    ]

channelRow : (Phoenix.Channel.Channel Msg) -> Html Msg
channelRow channel =
  tr []
    [ td [] [ text channel.name ]
    , td [] [ (text << toString) channel.payload ]
    , td [] [ (text << toString) channel.state ]
    ]

newMessageForm : Model -> Html Msg
newMessageForm model =
  form [ onSubmit SendMessage ]
    [ input [ type' "text", value model.newMessage, onInput SetNewMessage ] []
    ]

renderMessage : String -> Html Msg
renderMessage str =
  li [] [ text str ]
