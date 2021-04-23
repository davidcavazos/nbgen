# NbGen

Convert Jupyter notebooks into tested interactive documentation.

This project uses [Elm](https://elm-lang.org), which is a functional language
that guarantees _no runtime exceptions_.
If it compiles, it's correct and it will never crash.

> ℹ️ Make sure you have [Elm installed](https://guide.elm-lang.org/install/elm.html).

## Installing as an Elm library

To import this from an Elm application or library.

```sh
elm install davidcavazos/nbgen
```

Then, you can import it and use it in your Elm application or library.

```elm
import NbGen exposing (Cell(..), Notebook, fromString, toString)
import Json.Decode as D

notebook : Result D.Error Notebook
notebook =
    fromString
        """
        { "cells":
          [ { "cell_id": "markdown-cell-id"
            , "cell":
              { "cell_type": "markdown"
              , "source":
                [ "This is a Markdown cell!\\n"
                , "With multiple lines.\\n"
                ]
              }
            }
          , { "cell":
              { "cell_type": "code"
              , "metadata": { "tags": ["testing"] }
              , "source":
                [ "# This is a code cell!\\n"
                , "print('The default kernel is python3')\\n"
                ]
              , "outputs":
                [ { "output_type": "stream"
                  , "name": "stdout"
                  , "text": "The default kernel is python3"
                  }
                ]
              }
            }
          ]
        }
        """

notebook
--> Ok { title = "This is a Markdown cell!"
--> , kernel = "python3"
--> , authors = []
--> , cells =
-->     [ { id = "markdown-cell-id"
-->       , cell =
-->         MarkdownCell
-->           { tags = []
-->           , source =
-->             [ "This is a Markdown cell!\n"
-->             , "With multiple lines.\n"
-->             ]
-->           }
-->       }
-->     , { id = "this-is-a-code-cell"
-->       , cell =
-->         CodeCell
-->           { tags = [ "testing" ]
-->           , source =
-->             [ "# This is a code cell!\n"
-->             , "print('The default kernel is python3')\n"
-->             ]
-->           , outputs = [ "The default kernel is python3" ]
-->           }
-->       }
-->     ]
--> }

Result.map toString notebook
--> Ok
-->   (String.join "\n"
-->     [ "{"
-->     , "  \"metadata\": {"
-->     , "    \"kernel_info\": {"
-->     , "      \"name\": \"python3\""
-->     , "    }"
-->     , "  },"
-->     , "  \"nbformat\": 4,"
-->     , "  \"nbformat_minor\": 5,"
-->     , "  \"cells\": ["
-->     , "    {"
-->     , "      \"cell_id\": \"markdown-cell-id\","
-->     , "      \"cell\": {"
-->     , "        \"metadata\": {},"
-->     , "        \"source\": ["
-->     , "          \"This is a Markdown cell!\\n\","
-->     , "          \"With multiple lines.\\n\""
-->     , "        ]"
-->     , "      }"
-->     , "    },"
-->     , "    {"
-->     , "      \"cell_id\": \"this-is-a-code-cell\","
-->     , "      \"cell\": {"
-->     , "        \"metadata\": {"
-->     , "          \"tags\": ["
-->     , "            \"testing\""
-->     , "          ]"
-->     , "        },"
-->     , "        \"source\": ["
-->     , "          \"# This is a code cell!\\n\","
-->     , "          \"print('The default kernel is python3')\\n\""
-->     , "        ],"
-->     , "        \"outputs\": ["
-->     , "          {"
-->     , "            \"output_type\": \"stream\","
-->     , "            \"name\": \"stdout\","
-->     , "            \"text\": \"The default kernel is python3\""
-->     , "          }"
-->     , "        ]"
-->     , "      }"
-->     , "    }"
-->     , "  ]"
-->     , "}"
-->     ]
-->   )
```

## Running as a command line tool

Since Elm compiles to Javascript, we can run it with [Node.js](https://nodejs.org/en/about).

> ℹ️ Make sure you have [Node.js installed](https://nodejs.dev/learn/how-to-install-nodejs).
