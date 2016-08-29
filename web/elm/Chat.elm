module Chat exposing (..) --where

import Html exposing (Html, div, text, ul, li, input, button, form, span)
import Html.Attributes exposing (type', value, placeholder, name, id, class, classList)
import Html.Events exposing (onInput, onSubmit, onClick, onCheck)

import Routes
import Models exposing (..)

view : Model -> Html Msg
view model =
  div [ id "chat-container" ]
    [ div [ id "chat-list-box"]
      [ ul [ id "chat-list" ] ((List.reverse << List.map renderMessage) model.messages) ]
    , newMessageForm model
    ]

newMessageForm : Model -> Html Msg
newMessageForm model =
  form [ onSubmit SendMessage ]
    [ input [ type' "text", value model.newMessage, onInput SetNewMessage ] []
    ]

renderMessage : ChatMessage -> Html Msg
renderMessage msg =
  li []
    [ span [ classList [
                ("team-" ++ msg.team, True),
                ("rank-" ++ msg.rank, True)]]
      [text (Maybe.withDefault "anonymous" msg.user)]
    , text (": " ++ msg.body)]
