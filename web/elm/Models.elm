module Models exposing (..)

import Dict
import Phoenix.Socket
import Json.Encode as JE
import Json.Decode as JD exposing ((:=))

import Routes

-- Constants

socketServer : String
socketServer = "ws://dbordak.com:4000/socket/websocket"

-- Init

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
  Phoenix.Socket.init socketServer
    |> Phoenix.Socket.withDebug

initModel : Model
initModel =
  Model "" [] False [] "" "" Routes.Lobby "" Dict.empty initPhxSocket

-- Models

type alias Space =
  { color: String
  , touched: Bool}

type alias Model =
  { activeWord : String
  , board : List (List String)
  , enableButtons : Bool
  , messages : List String
  , name : String
  , newMessage : String
  , page : Routes.Page
  , playerStatus : String
  , wordMap : Dict.Dict String Space
  , phxSocket : Phoenix.Socket.Socket Msg
  }

type Msg
  = PhoenixMsg (Phoenix.Socket.Msg Msg)
  | JoinChannel
  | SetName String
  | SendMessage
  | ReceiveChatMessage JE.Value
  | SetNewMessage String
  | SetActiveWord String
  | TouchWord
  | ReceiveWordMap JE.Value
  | ReceiveBoard JE.Value
  | ReceiveNewUserMessage JE.Value
  | LeaveChannel
  | StartGame
  | ReceiveInitialData JE.Value
  | JoinNewGame
  | ReceiveGameId JE.Value
  | GetGamesList
  | ShowJoinedMessage String
  | ShowLeftMessage String
  | NoOp

-- Json Decoders

type alias ChatMessage =
  { user : String
  , body : String
  }

chatMessageDecoder : JD.Decoder ChatMessage
chatMessageDecoder =
  JD.object2 ChatMessage
    ("user" := JD.string)
    ("body" := JD.string)

type alias NewUserMessage =
  { player_id : String }

newUserDecoder : JD.Decoder NewUserMessage
newUserDecoder =
  JD.object1 NewUserMessage
    ("player_id" := JD.string)

type alias InitialDataMessage =
  { board : List (List String)
  , player_status : String
  , enable_buttons : Bool
  , word_map : Dict.Dict String Space
  }

initialDataDecoder : JD.Decoder InitialDataMessage
initialDataDecoder =
  JD.object4 InitialDataMessage
    ("board" := JD.list (JD.list JD.string))
    ("player_status" := JD.string)
    ("enable_buttons" := JD.bool)
    ("word_map" := JD.dict spaceDecoder)

type alias BoardMessage =
  { player_id : String
  , board : List (List String)
  }

boardDecoder : JD.Decoder BoardMessage
boardDecoder =
  JD.object2 BoardMessage
    ("player_id" := JD.string)
    ("board" := JD.list (JD.list JD.string))

type alias WordMapMessage =
  {word_map : Dict.Dict String Space}

wordMapDecoder : JD.Decoder WordMapMessage
wordMapDecoder =
  JD.object1 WordMapMessage
    ("word_map" := JD.dict spaceDecoder)

spaceDecoder : JD.Decoder Space
spaceDecoder =
  JD.object2 Space
    ("color" := JD.string)
    ("touched" := JD.bool)

type alias GameIdMessage =
  {game_id : String}

gameIdDecoder : JD.Decoder GameIdMessage
gameIdDecoder =
  JD.object1 GameIdMessage
    ("game_id" := JD.string)
