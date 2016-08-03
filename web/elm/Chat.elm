module Chat exposing (..) --where

import Html exposing (Html, h3, div, text, ul, li, input, form, button, br, table, tbody, tr, td, span)
import Html.Attributes exposing (type', value)
import Html.Events exposing (onInput, onSubmit, onClick)
import Html.App
import Platform.Cmd
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing ((:=))
import Dict

-- MAIN

main : Program Never
main =
  Html.App.program
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }


-- CONSTANTS


socketServer : String
socketServer = "ws://localhost:4000/socket/websocket"


-- MODEL


type Msg
  = SetName String
  | SendMessage
  | SetNewMessage String
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | ReceiveChatMessage JE.Value
  | ReceiveNewUserMessage JE.Value
  | JoinChannel
  | LeaveChannel
  | ShowJoinedMessage String
  | ShowLeftMessage String
  | NoOp


type alias Model =
  { name : String
  , newMessage : String
  , messages : List String
  , phxSocket : Phoenix.Socket.Socket Msg
  }

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
  Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug
    |> Phoenix.Socket.on "new:msg" "rooms:lobby" ReceiveChatMessage
    |> Phoenix.Socket.on "user:entered" "rooms:lobby" ReceiveNewUserMessage

initModel : Model
initModel =
  Model "" "" [] initPhxSocket


init : ( Model, Cmd Msg )
init =
  ( initModel, Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg

-- COMMANDS


-- PHOENIX STUFF

type alias ChatMessage =
  { user : String
  , body : String
  }

extractString : JD.Decoder String
extractString =
  JD.tuple1 identity JD.string

chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
  JD.object2 ChatMessage
    ("user" := JD.string)
    ("body" := JD.string)

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    SendMessage ->
      let
        payload = (JE.object [ ("user", JE.string model.name), ("body", JE.string model.newMessage) ])
        push' =
          Phoenix.Push.init "new:msg" "rooms:lobby"
            |> Phoenix.Push.withPayload payload
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model
          | newMessage = ""
          , phxSocket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd
        )

    SetName str ->
      ( { model | name = str }
      , Cmd.none
      )

    SetNewMessage str ->
      ( { model | newMessage = str }
      , Cmd.none
      )

    ReceiveChatMessage raw ->
      case JD.decodeValue chatMessageDecoder raw of
        Ok chatMessage ->
          ( { model | messages = (chatMessage.user ++ ": " ++ chatMessage.body) :: model.messages }
          , Cmd.none
          )
        Err error ->
          ( model, Cmd.none )

    ReceiveNewUserMessage raw ->
        case JD.decodeValue extractString raw of
            Ok str ->
                ({ model | messages = (str ++ " has entered.") :: model.messages}
                , Cmd.none)
            Err error ->
                ( model, Cmd.none )

    JoinChannel ->
      let
        channel =
          Phoenix.Channel.init "rooms:lobby"
            |> Phoenix.Channel.withPayload (JE.object [ ("user_id", JE.string model.name) ])
            |> Phoenix.Channel.onJoin (always (ShowJoinedMessage "rooms:lobby"))
            |> Phoenix.Channel.onClose (always (ShowLeftMessage "rooms:lobby"))

        (phxSocket, phxCmd) = Phoenix.Socket.join channel model.phxSocket
      in
        ({ model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    LeaveChannel ->
      let
        (phxSocket, phxCmd) = Phoenix.Socket.leave "rooms:lobby" model.phxSocket
      in
        ({ model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    ShowJoinedMessage channelName ->
      ( { model | messages = ("Joined channel " ++ channelName) :: model.messages }
      , Cmd.none
      )

    ShowLeftMessage channelName ->
      ( { model | messages = ("Left channel " ++ channelName) :: model.messages }
      , Cmd.none
      )

    NoOp ->
      ( model, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h3 [] [ text "Channels:" ]
    , div
        []
        [ input [type' "text", value model.name, onInput SetName ] []
        , button [ onClick JoinChannel ] [ text "Join channel" ]
        , button [ onClick LeaveChannel ] [ text "Leave channel" ]
        ]
    , channelsTable (Dict.values model.phxSocket.channels)
    , br [] []
    , h3 [] [ text "Messages:" ]
    , newMessageForm model
    , ul [] ((List.reverse << List.map renderMessage) model.messages)
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
