%%%-------------------------------------------------------------------
%% @doc my_pz_server top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(my_pz_server_sup).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    {ok,Pools} = application:get_env(my_pz_server, db),

    PoolOptions = proplists:get_value(poolConf, Pools),
    MySqlOptions = proplists:get_value(sqlConf, Pools),

    {ok,
     {{one_for_one, 5, 10}, [mysql_poolboy:child_spec(pool1, PoolOptions, MySqlOptions)]}}.

%% internal functions
