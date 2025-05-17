%% coding: utf-8
-module(api_user_info).
-compile(export_all).

init(Req, Opts) ->
  {cowboy_rest, Req, Opts}.


  allowed_methods(Req, State) ->
    {[<<"POST">>, <<"OPTIONS">>], Req, State}.
  

content_types_accepted(Req, State) ->
  {[
    {<<"application/x-www-form-urlencoded">>, json_post},
    {<<"application/json">>, json_post},
    {<<"application/json;charset=utf-8">>, json_post}
  ], Req, State}.

make_response(Code, Msg, Data) ->
  iolist_to_binary(json:encode(#{
    <<"code">> => Code,
    <<"msg">> => Msg,
    <<"data">> => Data
  })).


json_post(Req, State) ->
  io:format("dddddddddd"),
  Result =
    try
      Sql3 = "SELECT * from info ",
      try
        {ok, FieldList, DataList} = mysql_poolboy:query(pool1, Sql3),
        case DataList of
          [] -> make_response(-1, <<"no data">>, []);
          _ ->
            DataMaps = [ maps:from_list(lists:zip(FieldList, D)) || D <- DataList ],
            make_response(0, <<"succ">>, DataMaps)
        end
      catch
        _:_ -> make_response(1, <<"error">>, <<>>)
      end
    catch
      _:_ -> make_response(1, <<"error param">>, <<>>)
    end,

    NewReq1 = cowboy_req:set_resp_body(Result, Req),
    NewReq2 = cowboy_req:set_resp_header(<<"content-type">>, <<"application/json">>, NewReq1),
    {true, NewReq2, State}.

