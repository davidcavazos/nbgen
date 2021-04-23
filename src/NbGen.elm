module NbGen exposing (Cell(..), Notebook, cellSource, cellTags, fromString, toString, validId)

import Json.Decode as D
import Json.Encode as E
import Regex



-- Notebook format:
--      https://nbformat.readthedocs.io/en/latest/format_description.html
-- Kernel specs:
--      https://jupyter-client.readthedocs.io/en/stable/kernels.html#kernel-specs


type alias Notebook =
    { title : String
    , kernel : String
    , authors : List String
    , cells : List { id : String, cell : Cell }
    }


type Cell
    = MarkdownCell
        { tags : List String
        , source : List String
        }
    | CodeCell
        { tags : List String
        , source : List String
        , outputs : List String
        }


{-| Parses a `Notebook` from a JSON string.

Invalid cells or parameters are ignored.

-}
fromString : String -> Result D.Error Notebook
fromString txt =
    let
        optional : D.Decoder a -> a -> D.Decoder a
        optional decoder default =
            D.maybe decoder |> D.map (Maybe.withDefault default)

        decodeMetadata : D.Decoder { tags : List String }
        decodeMetadata =
            D.map (\tags -> { tags = tags })
                (optional (D.field "tags" (D.list D.string)) [])

        decodeCell : D.Decoder Cell
        decodeCell =
            D.map4
                (\cell_type { tags } source outputs ->
                    if cell_type == "code" then
                        CodeCell { tags = tags, source = source, outputs = outputs }

                    else
                        MarkdownCell { tags = tags, source = source }
                )
                (optional (D.field "cell_type" D.string) "markdown")
                (optional (D.field "metadata" decodeMetadata) { tags = [] })
                (optional (D.field "source" (D.list D.string)) [])
                (optional (D.field "outputs" (D.list (D.field "text" D.string))) [])

        decodeCellWithId : D.Decoder { id : String, cell : Cell }
        decodeCellWithId =
            D.map2 (\id cell -> { id = id, cell = cell })
                (optional (D.field "cell_id" D.string) "")
                (D.field "cell" decodeCell)
                |> D.map inferCellId
    in
    D.decodeString
        (D.map4 Notebook
            (optional (D.field "title" D.string) "")
            (optional (D.field "kernel" D.string) "python3")
            (optional (D.field "authors" (D.list D.string)) [])
            (optional (D.field "cells" (D.list decodeCellWithId)) [])
            |> D.map inferNotebookTitle
        )
        txt


{-| Writes a `Notebook` to a valid Jupyter notebook JSON string.
-}
toString : Notebook -> String
toString nb =
    let
        encodeMetadata : { tags : List String } -> E.Value
        encodeMetadata { tags } =
            E.object
                (if List.isEmpty tags then
                    []

                 else
                    [ ( "tags", E.list E.string tags ) ]
                )

        encodeCell : { id : String, cell : Cell } -> E.Value
        encodeCell { id, cell } =
            E.object
                [ ( "cell_id", E.string id )
                , ( "cell"
                  , case cell of
                        MarkdownCell { tags, source } ->
                            E.object
                                [ ( "metadata", encodeMetadata { tags = tags } )
                                , ( "source", E.list E.string source )
                                ]

                        CodeCell { tags, source, outputs } ->
                            E.object
                                [ ( "metadata", encodeMetadata { tags = tags } )
                                , ( "source", E.list E.string source )
                                , ( "outputs"
                                  , E.list E.object
                                        (List.map
                                            (\text ->
                                                [ ( "output_type", E.string "stream" )
                                                , ( "name", E.string "stdout" )
                                                , ( "text", E.string text )
                                                ]
                                            )
                                            outputs
                                        )
                                  )
                                ]
                  )
                ]
    in
    E.object
        [ ( "metadata"
          , E.object
                [ ( "kernel_info"
                  , E.object [ ( "name", E.string nb.kernel ) ]
                  )
                ]
          )
        , ( "nbformat", E.int 4 )
        , ( "nbformat_minor", E.int 5 )
        , ( "cells", E.list encodeCell nb.cells )
        ]
        |> E.encode 2


cellSource : Cell -> List String
cellSource cell =
    case cell of
        MarkdownCell { source } ->
            source

        CodeCell { source } ->
            source


cellTags : Cell -> List String
cellTags cell =
    case cell of
        MarkdownCell { tags } ->
            tags

        CodeCell { tags } ->
            tags


{-| Converts a `String` into a valid cell ID.

A valid cell ID consists of 1 to 64 letters `a-zA-Z`, numbers `0-9`, hyphens `-` and underscores `_`.

    import List exposing (repeat)
    import String exposing (fromList)

    validId ""                             --> "_"
    validId "_-Abc-123-_"                  --> "abc-123"
    validId "a~!@#$%^&*()=+b[]{};:,.<>?/c" --> "a-b-c"
    validId (fromList (repeat 100 'a'))    --> fromList (repeat 64 'a')

-}
validId : String -> String
validId txt =
    let
        invalidChars =
            Maybe.withDefault Regex.never (Regex.fromString "[^-\\w]+")

        trimChars =
            Maybe.withDefault Regex.never (Regex.fromString "^[-_]+|[-_]+$")
    in
    txt
        |> Regex.replace invalidChars (\_ -> "-")
        |> Regex.replace trimChars (\_ -> "")
        |> String.left 64
        |> String.toLower
        |> String.pad 1 '_'



-- Local and helper functions


inferCellId : { id : String, cell : Cell } -> { id : String, cell : Cell }
inferCellId { id, cell } =
    { id =
        if id == "" then
            List.head (cellSource cell)
                |> Maybe.withDefault ""
                |> validId

        else
            validId id
    , cell = cell
    }


inferNotebookTitle : Notebook -> Notebook
inferNotebookTitle nb =
    { nb
        | title =
            if nb.title == "" then
                List.head nb.cells
                    |> Maybe.map .cell
                    |> Maybe.map cellSource
                    |> Maybe.andThen List.head
                    |> Maybe.withDefault ""
                    |> String.trim

            else
                ""
    }
