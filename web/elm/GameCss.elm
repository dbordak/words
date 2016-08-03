module GameCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, li, input)
import Css.Namespace exposing (namespace)

type CssClasses
  = WordLabel

type CssIds
  = Dummy

css =
  (stylesheet << namespace "words")
    [ input
        [ display none]
    , (.) WordLabel
        [ display block
        , backgroundColor (hex "e7e7e7")
        , border3 (px 2) solid (hex "ddd")
        , borderRadius (px 5)
        , padding (px 10)
        , textAlign center
        , color (rgb 0 255 0)
        ]]
