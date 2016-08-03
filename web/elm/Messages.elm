module Messages exposing (..)

import Phoenix.Socket
import Json.Encode as JE

type Msg
  = PhoenixMsg (Phoenix.Socket.Msg Msg)
  | SetName String
  | SendMessage
  | SetNewMessage String
  | SetActiveWord String
  | TouchWord
  | ReceiveWordMap JE.Value
  | ReceiveBoard JE.Value
  | ReceiveNewUserMessage JE.Value
  | JoinChannel
  | LeaveChannel
  | StartGame
  | ReceiveInitialData JE.Value
  | GetGamesList
  | ShowJoinedMessage String
  | ShowLeftMessage String
  | NoOp
