module Main exposing (main)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Decode as JD
import Json.Encode as JE
import Platform.Cmd
import Navigation
import Dict
import Html
import String

import Routes exposing (pageChannel)
import Game
import Lobby
import Models exposing (..)


init : Result String Routes.Page -> ( Model, Cmd Msg )
init result =
  urlUpdate result initModel


subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg


urlUpdate : Result String Routes.Page -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  let
    (tempModel, urlCmd) =
      case Debug.log "result" result of
        Err _ ->
          ( model, Navigation.modifyUrl (Routes.toUrl model.page) )
        Ok page ->
          ({ model | page = page}, Cmd.none)
    (model, joinCmd) = update JoinChannel tempModel
  in
    (model, Cmd.batch [joinCmd, urlCmd])

update : Msg -> Model -> ( Model, Cmd Msg)
update msg model =
  case msg of
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        ( { model | phxSocket = phxSocket }
        , Cmd.map PhoenixMsg phxCmd
        )

    JoinChannel ->
      let
        channel = Phoenix.Channel.init (pageChannel model.page)
        (phxSocket, phxCmd) = Phoenix.Socket.join channel model.phxSocket
        tempModel = {model | phxSocket = phxSocket}
        (newModel, chanCmd) = case model.page of
          Routes.Lobby ->
            update GetGamesList tempModel
          Routes.Game _ ->
            update StartGame tempModel
      in
        (newModel
        , Cmd.batch [chanCmd, (Cmd.map PhoenixMsg phxCmd)])

    SetNewMessage str ->
      ( { model | newMessage = str }
      , Cmd.none
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

    ReceiveChatMessage raw ->
      case JD.decodeValue chatMessageDecoder raw of
        Ok chatMessage ->
          ( { model | messages = (chatMessage.user ++ ": " ++ chatMessage.body) :: model.messages }
          , Cmd.none
          )
        Err error ->
          ( model, Cmd.none )

    SetName str ->
      ( { model | name = str }
      , Cmd.none
      )

    SetNewHintWord str ->
      let
        oldNewHint = model.newHint
        newHint = { oldNewHint | word = str}
      in
        ( { model | newHint = newHint}
        , Cmd.none
        )

    SetNewHintCount str ->
      let
        oldNewHint = model.newHint
        newHint = case String.toInt str of
          Ok newCount ->
            { oldNewHint | count = newCount}
          Err _ ->
            oldNewHint
      in
        ( { model | newHint = newHint}
        , Cmd.none
        )

    SendNewHint ->
      let
        payload = (JE.object [ ("word", JE.string model.newHint.word), ("count", JE.int model.newHint.count) ])
        push' =
          Phoenix.Push.init "game:hint" (pageChannel model.page)
            |> Phoenix.Push.withPayload payload
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model
          | newHint = (Hint "" 0 "")
          , phxSocket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd
        )

    TouchWord ->
      let
        payload = (JE.object [ ("word", JE.string model.activeWord)])
        push' =
          Phoenix.Push.init "game:touch" (pageChannel model.page)
            |> Phoenix.Push.withPayload payload
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model | phxSocket = phxSocket}
        , Cmd.map PhoenixMsg phxCmd
        )

    PassTurn ->
      let
        push' = Phoenix.Push.init "game:pass" (pageChannel model.page)
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model | phxSocket = phxSocket}
        , Cmd.map PhoenixMsg phxCmd
        )

    ReceiveTurnInfo raw ->
      case JD.decodeValue turnInfoDecoder raw of
        Ok turnInfoMessage ->
          (case turnInfoMessage.word_map of
             Just wordMap ->
               { model
                 | wordMap = wordMap
                 , turn = turnInfoMessage.turn}
             Nothing ->
               { model | turn = turnInfoMessage.turn}
          , Cmd.none)
        Err error ->
          ( model , Cmd.none )

    ReceiveHint raw ->
      case JD.decodeValue hintDecoder raw of
        Ok hint ->
          ({ model | hint = hint}, Cmd.none)
        Err error ->
          ( model , Cmd.none )

    SetActiveWord str ->
      ( { model | activeWord = str }
      , Cmd.none
      )

    ReceiveBoard raw ->
      case JD.decodeValue boardDecoder raw of
        Ok boardMessage ->
          ( { model | board = boardMessage.board}
          , Cmd.none
          )
        Err error ->
          ( model , Cmd.none )

    ReceiveNewUserMessage raw ->
        case JD.decodeValue newUserDecoder raw of
            Ok user ->
                ({ model | messages = (user.player_id ++ " has entered.")
                 :: model.messages}
                , Cmd.none)
            Err error ->
                ( model, Cmd.none )

    StartGame ->
      let
        push' =
          Phoenix.Push.init "game:joined" (pageChannel model.page)
            |> Phoenix.Push.onOk ReceiveInitialData
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model
          | newMessage = ""
          , phxSocket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd)

    -- TODO
    GameOver raw ->
      (model, Cmd.none)

    ReceiveInitialData raw ->
      case JD.decodeValue initialDataDecoder raw of
        Ok initialDataMessage ->
          let
            phxSocket =
              if initialDataMessage.player_info.can_hint then
                model.phxSocket
                  |> Phoenix.Socket.on "game:tl_touch" (pageChannel model.page) ReceiveTurnInfo
                  |> Phoenix.Socket.on "game:hint" (pageChannel model.page) ReceiveHint
                  |> Phoenix.Socket.on "game:over" (pageChannel model.page) GameOver
              else
                model.phxSocket
                  |> Phoenix.Socket.on "game:touch" (pageChannel model.page) ReceiveTurnInfo
                  |> Phoenix.Socket.on "game:hint" (pageChannel model.page) ReceiveHint
                  |> Phoenix.Socket.on "game:over" (pageChannel model.page) GameOver
          in
            ( { model
                | board = initialDataMessage.board
                , playerStatus = "You are " ++ initialDataMessage.player_status
                , wordMap = initialDataMessage.word_map
                , hint = initialDataMessage.hint
                , turn = initialDataMessage.turn
                , playerInfo = initialDataMessage.player_info
                , phxSocket = phxSocket }
            , Cmd.none
          )
        Err error ->
          ( { model | playerStatus = error} , Cmd.none )

    JoinNewGame ->
      let
        push' = Phoenix.Push.init "new_game" "lobby"
                |> Phoenix.Push.onOk ReceiveGameId
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
      in
        ( { model
          | newMessage = ""
          , phxSocket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd
        )

    ReceiveGameId raw ->
      case JD.decodeValue gameIdDecoder raw of
        Ok gameId ->
          (model, Navigation.newUrl (Routes.toUrl (Routes.Game gameId.game_id)))
        Err error ->
          ( model, Cmd.none )

    GetGamesList ->
      let
        push' =
          Phoenix.Push.init "current_games" "lobby"
        (phxSocket, phxCmd) = Phoenix.Socket.push push' model.phxSocket
               --  ({ model | messages = (str ++ " has entered.") :: model.messages}
      in
        ( { model
          | newMessage = ""
          , phxSocket = phxSocket
          }
        , Cmd.map PhoenixMsg phxCmd
        )

    LeaveChannel ->
      let
        (phxSocket, phxCmd) = Phoenix.Socket.leave "lobby" model.phxSocket
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


view : Model -> Html.Html Msg
view model =
  case model.page of
    Routes.Game _ ->
      Game.view model
    Routes.Lobby ->
      Lobby.view model


main : Program Never
main =
  Navigation.program (Navigation.makeParser Routes.urlParser)
    { init = init
    , view = view
    , update = update
    , urlUpdate = urlUpdate
    , subscriptions = subscriptions
    }


    -- |> Phoenix.Socket.on "game:player_joined" model.channel ReceiveNewUserMessage
