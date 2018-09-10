module Types exposing (..)

-- builtin
import Dict exposing (Dict)
import Http
import Dom
import Navigation
import Mouse
import Time exposing (Time)
import PageVisibility

-- libs
import Keyboard.Event exposing (KeyboardEvent)

type alias Exception =
  { short : String
  , long : Maybe String
  , tipe : String
  , actual : Maybe String
  , actualType : Maybe String
  , result : Maybe String
  , resultType : Maybe String
  , expected : Maybe String
  , info : Dict String String
  , workarounds : List String }

type Tipe = TInt
          | TStr
          | TChar
          | TBool
          | TFloat
          | TObj
          | TList
          | TAny
          | TNull
          | TBlock
          | TIncomplete
          | TError
          | TResp
          | TDB
          | TID
          | TDate
          | TTitle
          | TUrl
          | TPassword
          | TUuid
          | TOption
          | TErrorRail
          | TBelongsTo String
          | THasMany String
          | TDbList Tipe

type Dhttp = Redirect String
           | Response Int (List (String, String))

type Dval = DInt Int
          | DFloat Float
          | DBool Bool
          | DNull
          | DChar Char
          | DStr String
          | DList (List Dval)
          | DObj (Dict String Dval)
          | DIncomplete
          | DError String
          | DBlock
          | DErrorRail Dval
          | DResp Dhttp Dval
          | DDB String
          | DID String
          | DDate String
          | DTitle String
          | DUrl String
          | DPassword String
          | DUuid String
          | DOption (Maybe Dval)


-- There are two coordinate systems. Pos is an absolute position in the
-- canvas. Nodes and Edges have Pos'. VPos is the viewport: clicks occur
-- within the viewport and we map Absolute positions back to the
-- viewport to display in the browser.
-- TODO: Can we depreciate VPos?
type alias Pos = {x: Int, y: Int }
type alias VPos = {vx: Int, vy: Int }

type alias MouseEvent = {pos: VPos, button: Int}
type alias IsLeftButton = Bool

type alias Special = Int
type TLID = TLID Int
type ID = ID Int

-----------------------------
-- CursorState
-----------------------------
type alias DarkKeyboardEvent =
    { standard : KeyboardEvent
    , selectionStart : Maybe Int
    , selectionEnd : Maybe Int
    }
type EntryCursor = Creating Pos
                 | Filling TLID ID

type alias HasMoved = Bool
type CursorState = Selecting TLID (Maybe ID)
                 | Entering EntryCursor
                 | Dragging TLID VPos HasMoved CursorState
                 | SelectingCommand TLID ID
                 | Deselected


-----------------------------
-- Msg
-- main Elm Architecture bus type
-----------------------------
type TimerAction = RefreshAnalysis
                 | CheckUrlHashPosition

type alias GlobalVariable = String
type alias RPCResult = ( List Toplevel
                       , List Toplevel -- deleted
                       , Traces
                       , List GlobalVariable
                       , List UserFunction
                       , List TLID)
type alias DvalArgsHash = String
type alias ExecuteFunctionRPCResult = (Dval, DvalArgsHash)
type alias GetAnalysisResult = ( Traces
                               , List GlobalVariable
                               , List FourOhFour
                               , List TLID)
type alias InitialLoadResult = RPCResult
type Msg
    = GlobalClick MouseEvent
    | NothingClick MouseEvent
    | ToplevelMouseDown TLID MouseEvent
    -- we have the actual node when ToplevelMouseUp is created,
    -- but by the time we use it the proper node will be changed
    | ToplevelMouseUp TLID MouseEvent
    | ToplevelClick TLID MouseEvent
    | DragToplevel TLID Mouse.Position
    | EntryInputMsg String
    | EntrySubmitMsg
    | GlobalKeyPress DarkKeyboardEvent
    | AutocompleteClick String
    | FocusEntry (Result Dom.Error ())
    | FocusAutocompleteItem (Result Dom.Error ())
    | RPCCallback Focus RPCParams (Result Http.Error RPCResult)
    | SaveTestRPCCallback (Result Http.Error String)
    | GetAnalysisRPCCallback (Result Http.Error GetAnalysisResult)
    | InitialLoadRPCCallback Focus Modification (Result Http.Error InitialLoadResult)
    | LocationChange Navigation.Location
    | AddRandom
    | FinishIntegrationTest
    | SaveTestButton
    | ToggleTimers
    | ExecuteFunctionRPCCallback ExecuteFunctionRPCParams (Result Http.Error ExecuteFunctionRPCResult)
    | ExecuteFunctionButton TLID ID String
    | ExecuteFunctionCancel TLID ID
    | Initialization
    | CreateHandlerFrom404 FourOhFour
    | WindowResize Int Int
    | TimerFire TimerAction Time
    | JSError String
    | PageVisibilityChange PageVisibility.Visibility
    | PageFocusChange PageVisibility.Visibility
    | StartFeatureFlag
    | EndFeatureFlag ID Pick
    | ToggleFeatureFlag ID Bool
    | DeleteUserFunctionParameter UserFunction UserFunctionParameter
    | BlankOrClick TLID ID MouseEvent
    | BlankOrDoubleClick TLID ID MouseEvent
    | BlankOrMouseEnter TLID ID MouseEvent
    | BlankOrMouseLeave TLID ID MouseEvent
    | MouseWheel (Int, Int)
    | DataClick TLID Int MouseEvent
    | DataMouseEnter TLID Int MouseEvent
    | DataMouseLeave TLID Int MouseEvent
    | CreateRouteHandler
    | CreateDBTable
    | CreateFunction
    | ExtractFunction
    | DeleteUserFunction TLID
    | RestoreToplevel TLID
    | LockHandler TLID Bool
    | ReceiveAnalysis String
    | EnablePanning Bool
    | ShowErrorDetails Bool
    | StartMigration DB
    | CancelMigration DB
    | DeleteColInDB DBColumn TLID

type alias Predecessor = Maybe PointerData
type alias Successor = Maybe PointerData
type Focus = FocusNothing -- deselect
           | FocusExact TLID ID
           | FocusNext TLID (Maybe ID)
           | FocusPageAndCursor Page CursorState
           | FocusSame -- unchanged
           | FocusNoChange -- unchanged

-----------------------------
-- RPCs
-----------------------------
type alias RollbackID = ID
type alias RollforwardID = ID
type Op
    = SetHandler TLID Pos Handler
    | CreateDB TLID Pos DBName
    | AddDBCol TLID ID ID
    | SetDBColName TLID ID DBColName
    | SetDBColType TLID ID DBColType
    | DeleteTL TLID
    | MoveTL TLID Pos
    | TLSavepoint TLID
    | UndoTL TLID
    | RedoTL TLID
    | SetFunction UserFunction
    | DeleteFunction TLID
    | ChangeDBColName TLID ID DBColName
    | ChangeDBColType TLID ID DBColType
    | DeprecatedInitDbm TLID ID RollbackID RollforwardID DBMigrationKind
    | SetExpr TLID ID Expr
    | CreateDBMigration TLID RollbackID RollforwardID (List DBColumn)
    | AddDBColToDBMigration TLID ID ID
    | SetDBColNameInDBMigration TLID ID DBColName
    | SetDBColTypeInDBMigration TLID ID DBColType

type alias RPCParams = { ops : List Op }

type alias ExecuteFunctionRPCParams =
  { tlid: TLID
  , traceID : String
  , callerID : ID
  , args : List Dval
  , fnName : String
  }

type alias AnalysisParams = List TLID


-----------------------------
-- Autocompletes
-----------------------------
type alias Autocomplete = { functions : List Function
                          , admin : Bool -- flagging hack
                          , completions : List (List AutocompleteItem)
                          , allCompletions : List AutocompleteItem
                          , index : Int
                          , value : String
                          , target : Maybe (TLID, PointerData)
                          , tipe : Maybe Tipe
                          , isCommandMode : Bool
                          }

type StringEntryPermission = StringEntryAllowed
                           | StringEntryNotAllowed

type StringEntryWidth = StringEntryNormalWidth
                      | StringEntryShortWidth

type alias Literal = String
type OmniAction = NewDB DBName
                | NewHandler
                | NewFunction (Maybe String)
                | NewHTTPHandler
                | NewHTTPRoute String
                | NewEventSpace String

type Keyword = KLet
             | KIf
             | KLambda

type alias Command = { name: String
                     , action : Model -> Toplevel -> PointerData -> Modification
                     , doc : String
                     , shortcut : String
                     }

type AutocompleteItem = ACFunction Function
                      | ACField String
                      | ACVariable VarName
                      | ACExtra String
                      | ACLiteral Literal
                      | ACOmniAction OmniAction
                      | ACKeyword Keyword
                      | ACCommand Command

type alias Target = (TLID, PointerData)
type AutocompleteMod = ACSetQuery String
                     | ACAppendQuery String
                     | ACReset
                     | ACSelectDown
                     | ACSelectUp
                     | ACSetTarget (Maybe Target)
                     | ACRegenerate
                     | ACEnableCommandMode
                     -- | ACFilterByParamType Tipe NodeList



-----------------------------
-- AB tests
-----------------------------
type VariantTest = StubVariant

-----------------------------
-- View
-----------------------------
type alias Class = String


-----------------------------
-- FeatureFlags
-----------------------------
type Pick = PickA
          | PickB

type alias FFIntID = Int
type alias FFIsExpanded = Bool

type alias FlagsVS = Dict FFIntID FFIsExpanded

-----------------------------
-- AST
-----------------------------

type alias VarName = String
type alias FnName = String
type alias FieldName = String
type alias KeyName = String

type alias VarBind = BlankOr VarName
type alias Field = BlankOr FieldName
type alias Key = BlankOr KeyName
type alias LambdaParameter = BlankOr VarName

type alias Expr = BlankOr NExpr
type SendToRail = Rail | NoRail
type NExpr = If Expr Expr Expr
           | FnCall FnName (List Expr) SendToRail
           | Variable VarName
           | Let VarBind Expr Expr
           | Lambda (List LambdaParameter) Expr
           | Value String
           | ObjectLiteral (List (Key, Expr))
           | ListLiteral (List Expr)
           | Thread (List Expr)
           | FieldAccess Expr Field
           | FeatureFlag (BlankOr String) Expr Expr Expr

-----------------------------
-- Pointers
-----------------------------

type PointerData = PVarBind VarBind
                 | PEventName (BlankOr String)
                 | PEventModifier (BlankOr String)
                 | PEventSpace (BlankOr String)
                 | PExpr Expr
                 | PField Field
                 | PKey (BlankOr String)
                 | PDBColName (BlankOr String)
                 | PDBColType (BlankOr String)
                 | PDarkType DarkType
                 | PDarkTypeField (BlankOr String)
                 | PFFMsg (BlankOr String)
                 | PFnName (BlankOr String)
                 | PParamName (BlankOr String)
                 | PParamTipe (BlankOr Tipe)


type PointerType = VarBind
                 | EventName
                 | EventSpace
                 | EventModifier
                 | Expr
                 | Field
                 | Key
                 | DBColName
                 | DBColType
                 | DarkType
                 | DarkTypeField
                 | FFMsg
                 | FnName
                 | ParamName
                 | ParamTipe

type BlankOr a = Blank ID
               | F ID a

type PointerOwner = POSpecHeader
                  | POAst
                  | PODb
                  | POSpecType

-----------------------------
-- Top-levels
-----------------------------
type alias DarkType = BlankOr NDarkType
type NDarkType = DTEmpty -- empty body
               | DTAny
               | DTString
               | DTInt
               | DTObj (List (BlankOr String, DarkType))

type alias SpecTypes = { input : DarkType
                       , output : DarkType
                       }

type alias HandlerSpec = { module_ : BlankOr String
                         , name : BlankOr String
                         , modifier : BlankOr String
                         , types : SpecTypes
                         }

type HandlerSpace = HSHTTP
                  | HSCron
                  | HSOther
                  | HSEmpty

type alias Handler = { ast : Expr
                     , spec : HandlerSpec
                     , tlid : TLID
                     }

type alias DBName = String
type alias DBColName = String
type alias DBColType = String
type alias DBColumn = (BlankOr DBColName, BlankOr DBColType)

-- this is deprecated
type DBMigrationKind = DeprecatedMigrationKind

type DBMigrationState = DBMigrationAbandoned
                      | DBMigrationInitialized

type alias DBMigration = { startingVersion : Int
                         , version : Int
                         , state : DBMigrationState
                         , rollforward : Expr
                         , rollback : Expr
                         , cols : List DBColumn
                         }

type alias DB = { tlid : TLID
                , name : DBName
                , cols : List DBColumn
                , version : Int
                , oldMigrations : List DBMigration
                , activeMigration : Maybe DBMigration
                , newMigration: Maybe DBSchemaMigration
                }

type alias DBSchemaMigration =
  { cols : List DBColumn
  , rollback : Expr
  , rollforward : Expr
  , version : Int
  }

type TLData = TLHandler Handler
            | TLDB DB
            | TLFunc UserFunction

type alias Toplevel = { id : TLID
                      , pos : Pos
                      , data : TLData
                      }

-----------------------------
-- Analysis
-----------------------------
type alias LVDict = Dict Int Dval
type alias AVDict = Dict Int (List VarName)
type alias AnalysisResults = { liveValues : LVDict
                             , availableVarnames : AVDict
                             }
type alias Analyses = Dict TraceID AnalysisResults

-----------------------------
-- From the server
-----------------------------
type alias InputValueDict = Dict VarName Dval
type alias FunctionResult = { fnName : String
                            , callerID : ID
                            , argHash : String
                            , value : Dval
                            }
type alias TraceID = String
type alias Trace = { id: TraceID
                   , input: InputValueDict
                   , functionResults : List FunctionResult
                   }
type alias Traces = Dict Int (List Trace) -- tlid -> one trace per inputvalue

-- space i.e. "HTTP", path i.e. "/foo", modifier i.e. "GET/PATCH/PUT"
type alias FourOhFour = { space: String
                        , path: String
                        , modifier: String
                        }


-----------------------------
-- Canvas position
-----------------------------
type alias Name = String
type Page = Toplevels Pos
          | Fn TLID Pos

-----------------------------
-- Model
-----------------------------

type alias Clipboard = Maybe PointerData

type alias SyncState = { inFlight : Bool
                       , ticks : Int
                       }

type alias UrlState = { lastPos : Pos
                      }
type alias TLCursors = Dict Int Int

type alias CanvasProps =
  { offset: Pos
  , fnOffset: Pos
  , enablePan: Bool
  }

type alias Model = { error : DarkError
                   , lastMsg : Msg
                   , lastMod : Modification
                   , tests : List VariantTest
                   , complete : Autocomplete
                   , userFunctions : List UserFunction
                   , builtInFunctions : List Function
                   , cursorState : CursorState
                   , currentPage : Page
                   , hovering : List ID
                   , toplevels : List Toplevel
                   , deletedToplevels : List Toplevel
                   -- These are read direct from the server. The ones that are
                   -- analysed are in analysis
                   , traces : Traces
                   , analyses : Analyses
                   , globals : List GlobalVariable
                   , f404s : List FourOhFour
                   , unlockedDBs : List TLID
                   , integrationTestState : IntegrationTestState
                   , visibility : PageVisibility.Visibility
                   , clipboard : Clipboard
                   , syncState : SyncState
                   , urlState : UrlState
                   , timersEnabled : Bool
                   , executingFunctions: List (TLID, ID)
                   -- This is TLID id to cursor index (the cursor being
                   -- the input to the toplevel currently used, not to
                   -- be condused with cursorState, which is the code
                   -- that is currently selected.)
                   , tlCursors: TLCursors
                   , featureFlags: FlagsVS
                   , lockedHandlers: List TLID
                   , canvas: CanvasProps
                   }

-- Values that we serialize
type alias SerializableEditor = { clipboard : Maybe PointerData
                                , timersEnabled : Bool
                                , cursorState : CursorState
                                , lockedHandlers: List TLID
                                }

--------------------
-- Error Handling
--------------------

type alias DarkError  =
  { message : Maybe String
  , showDetails : Bool
  }

-----------------------------
-- Testing
-----------------------------

-- avoid ever-expanding aliases
type alias TestResult = Result String ()
type IntegrationTestState = IntegrationTestExpectation (Model -> TestResult)
                          | IntegrationTestFinished TestResult
                          | NoIntegrationTest


-----------------------------
-- Modifications
-----------------------------
type Modification = DisplayAndReportHttpError String Http.Error
                  | DisplayAndReportError String
                  | DisplayError String
                  | ClearError
                  | Select TLID (Maybe ID)
                  | SelectCommand TLID ID
                  | SetHover ID
                  | ClearHover ID
                  | Deselect
                  | RemoveToplevel Toplevel
                  | SetToplevels (List Toplevel) Bool
                  | UpdateToplevels (List Toplevel) Bool
                  | SetDeletedToplevels (List Toplevel)
                  | UpdateDeletedToplevels (List Toplevel)
                  | UpdateAnalysis TraceID AnalysisResults
                  | RequestAnalysis (List Toplevel)
                  | SetGlobalVariables (List GlobalVariable)
                  | SetUserFunctions (List UserFunction) Bool
                  | SetUnlockedDBs (List TLID)
                  | Set404s (List FourOhFour)
                  | Enter EntryCursor
                  | RPCFull (RPCParams, Focus)
                  | RPC (List Op, Focus) -- shortcut for RPCFull
                  | GetAnalysisRPC
                  | NoChange
                  | MakeCmd (Cmd Msg)
                  | AutocompleteMod AutocompleteMod
                  | Many (List Modification)
                  | Drag TLID VPos HasMoved CursorState
                  | TriggerIntegrationTest String
                  | EndIntegrationTest
                  | SetCursorState CursorState
                  | SetPage Page
                  | SetCenter Pos
                  | CopyToClipboard Clipboard
                  | SetCursor TLID Int
                  | ExecutingFunctionBegan TLID ID
                  | ExecutingFunctionRPC TLID ID String
                  | ExecutingFunctionComplete (List (TLID, ID))
                  | SetLockedHandlers (List TLID)
                  | MoveCanvasTo CanvasProps Page Pos
                  | UpdateTraces Traces
                  | UpdateTraceFunctionResult TLID TraceID ID FnName DvalArgsHash Dval
                  | UpdateDB DB
                  -- designed for one-off small changes
                  | TweakModel (Model -> Model)

-----------------------------
-- Flags / function types
-----------------------------

type alias Flags =
  { editorState: Maybe String
  , complete: List FlagFunction
  }


-- name, type optional
type alias Parameter = { name: String
                       , tipe: Tipe
                       , block_args: List String
                       , optional: Bool
                       , description: String
                       }

type alias Function = { name: String
                      , parameters: List Parameter
                      , description: String
                      , returnTipe: Tipe
                      , previewExecutionSafe: Bool
                      , deprecated: Bool
                      , infix: Bool
                      }

type alias UserFunctionParameter = { name: BlankOr String
                                   , tipe: BlankOr Tipe
                                   , block_args: List String
                                   , optional: Bool
                                   , description: String
                                   }

type alias UserFunctionMetadata = { name: BlankOr String
                                  , parameters: List UserFunctionParameter
                                  , description: String
                                  , returnTipe: BlankOr Tipe
                                  , infix: Bool
                                  }

type alias UserFunction = { tlid: TLID
                          , metadata: UserFunctionMetadata
                          , ast: Expr
                          }

type alias FlagParameter = { name: String
                           , tipe: String
                           , block_args: List String
                           , optional: Bool
                           , description: String
                           }

type alias FlagFunction = { name: String
                          , parameters: List FlagParameter
                          , description: String
                          , return_type: String
                          , preview_execution_safe: Bool
                          , deprecated: Bool
                          , infix: Bool
                          }
