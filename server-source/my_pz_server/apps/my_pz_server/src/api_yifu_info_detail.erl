%% coding: utf-8
-module(api_yifu_info_detail).
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
  %% 读取请求体
  {ok, Body, Req1} = cowboy_req:read_body(Req),
  io:format("Body Body: ~p~n", [Body]),
  %% 尝试解析 JSON 请求体
  Result =
    try
      %% 解析 JSON，得到的是 map()
      Map = json:decode(Body),
      io:format("Map Map: ~p~n", [Map]),
      %% 获取 today 参数
    Pdid = maps:get(<<"pdid">>, Map),
      io:format("Received Pdid: ~p~n", [Pdid]),

      %% 可选：执行根据 today 的查询
      Sql = "SELECT * FROM yifudetail WHERE pdid = ?",
      try
        {ok, FieldList, DataList} = mysql_poolboy:query(pool1, Sql, [Pdid]),
        case DataList of
          [] -> make_response(-1, <<"no data">>, []);
          _ ->
            DataMaps = [ maps:from_list(lists:zip(FieldList, D)) || D <- DataList ],
            make_response(0, <<"succ">>, DataMaps)
        end
      catch
        _:_ -> make_response(1, <<"db error">>, <<>>)
      end
    catch
      error:{badkey, _} -> make_response(1, <<"missing today param">>, <<>>);
      _:_ -> make_response(1, <<"json parse error">>, <<>>)
    end,

  %% 返回响应
  NewReq1 = cowboy_req:set_resp_body(Result, Req1),
  NewReq2 = cowboy_req:set_resp_header(<<"content-type">>, <<"application/json">>, NewReq1),
  {true, NewReq2, State}.

  



