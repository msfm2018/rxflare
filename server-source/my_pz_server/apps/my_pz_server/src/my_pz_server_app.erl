



-module(my_pz_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    UserRoutes = [
        % {"/api/user/info",     api_user_info,  #{methods => [post]}}
        {"/api/user/info",     api_user_info,  #{}}
        % {"/api/user/update",   api_user_info_update, #{}}
    ],
    ServiceOrderRoutes = [
        {"/api/server/yifuinfo",     api_yifu_info,  #{}},
        {"/api/server/yifuinfodetail",     api_yifu_info_detail,  #{}}        
    
    ],
    AllRoutes = UserRoutes ++ ServiceOrderRoutes++[
        {"/", toppage_h, []}
    ] ,
    Dispatch = cowboy_router:compile([
        {'_', AllRoutes}
        ]),

    {ok, _} = cowboy:start_clear(http, 
                                [{port, 9091}] ,
                                 #{env => #{dispatch => Dispatch}}),

    my_pz_server_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
