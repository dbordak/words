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
  Model "" [] [] "" "" Routes.Lobby "" Nothing Dict.empty Nothing
    (Hint "" 0 "" 0) (PlayerInfo False False False "" "") initPhxSocket

-- Models

type Team = Red | Blue

type alias Space =
  { color: String
  , touched: Bool}

type alias Hint =
  { word: String
  , count: Int
  , team: String
  , remaining: Int}

type alias Model =
  { activeWord : String
  , words : List String
  , messages : List String
  , name : String
  , newMessage : String
  , page : Routes.Page
  , turn : String
  , winner : Maybe String
  , wordMap : Dict.Dict String Space
  , hint : Maybe Hint
  , newHint : Hint
  , playerInfo : PlayerInfo
  , phxSocket : Phoenix.Socket.Socket Msg
  }

type Msg
  = PhoenixMsg (Phoenix.Socket.Msg Msg)
  | JoinChannel
  | SetName String
  | SendMessage
  | ReceiveChatMessage JE.Value
  | SetNewMessage String
  | SetNewHintWord String
  | SetNewHintCount String
  | SendNewHint
  | SetActiveWord String
  | TouchWord
  | PassTurn
  | ReceiveTurnInfo JE.Value
  | ReceiveHint JE.Value
  | ReceiveNewUserMessage JE.Value
  | LeaveChannel
  | StartGame
  | GameOver JE.Value
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
  { word_map : Dict.Dict String Space
  , hint : Maybe Hint
  , turn : String
  , player_info : PlayerInfo
  }

initialDataDecoder : JD.Decoder InitialDataMessage
initialDataDecoder =
  JD.object4 InitialDataMessage
    ("word_map" := JD.dict spaceDecoder)
    ("hint" := JD.maybe hintDecoder)
    ("turn" := JD.string)
    ("player_info" := playerInfoDecoder)

type alias TurnInfoMessage =
  { word_map : Maybe (Dict.Dict String Space)
  , turn : String}

turnInfoDecoder : JD.Decoder TurnInfoMessage
turnInfoDecoder =
  JD.object2 TurnInfoMessage
    (JD.maybe ("word_map" := JD.dict spaceDecoder))
    ("turn" := JD.string)

type alias GameIdMessage =
  {game_id : String}

gameIdDecoder : JD.Decoder GameIdMessage
gameIdDecoder =
  JD.object1 GameIdMessage
    ("game_id" := JD.string)

type alias PlayerInfo =
  { can_vote : Bool
  , can_touch : Bool
  , can_hint : Bool
  , id : String
  , team : String}

playerInfoDecoder : JD.Decoder PlayerInfo
playerInfoDecoder =
  JD.object5 PlayerInfo
    ("can_vote" := JD.bool)
    ("can_touch" := JD.bool)
    ("can_hint" := JD.bool)
    ("id" := JD.string)
    ("team" := JD.string)

type alias GameOverMessage =
  { winner : Maybe String }

gameOverDecoder : JD.Decoder GameOverMessage
gameOverDecoder =
  JD.object1 GameOverMessage
    ("winner" := JD.maybe JD.string)

hintDecoder : JD.Decoder Hint
hintDecoder =
  JD.object4 Hint
    ("word" := JD.string)
    ("count" := JD.int)
    ("team" := JD.string)
    ("remaining" := JD.int)

spaceDecoder : JD.Decoder Space
spaceDecoder =
  JD.object2 Space
    ("color" := JD.string)
    ("touched" := JD.bool)
