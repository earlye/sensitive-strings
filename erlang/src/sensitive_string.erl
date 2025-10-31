-module(sensitive_string).

%% API exports
-export([new/1, get_value/1, to_string/1, hash_hex/1, 
         is_sensitive_string/1, extract_value/1, extract_required_value/1, sensitive/1]).

%% For JSON encoding (jsx, jiffy, etc.)
-export([to_json/1]).

%% Record definition
-record(sensitive_string, {value :: binary()}).

%%====================================================================
%% API functions
%%====================================================================

%% @doc Creates a new sensitive_string from a binary or list
-spec new(binary() | list()) -> #sensitive_string{}.
new(Value) when is_binary(Value) ->
    #sensitive_string{value = Value};
new(Value) when is_list(Value) ->
    #sensitive_string{value = list_to_binary(Value)}.

%% @doc Gets the plaintext value (use only when you need the actual secret)
-spec get_value(#sensitive_string{}) -> binary().
get_value(#sensitive_string{value = Value}) ->
    Value.

%% @doc Returns the SHA256 hash as a binary string (for display/logging)
-spec to_string(#sensitive_string{}) -> binary().
to_string(#sensitive_string{value = Value}) ->
    Hash = hash_hex(Value),
    <<"sha256:", Hash/binary>>.

%% @doc Computes SHA256 hash as hex binary
-spec hash_hex(binary()) -> binary().
hash_hex(Value) ->
    Hash = crypto:hash(sha256, Value),
    bin_to_hex(Hash).

%% @doc For JSON encoding - returns the hash
-spec to_json(#sensitive_string{}) -> binary().
to_json(SensitiveString) ->
    to_string(SensitiveString).

%% @doc Check if value is a sensitive_string
-spec is_sensitive_string(term()) -> boolean().
is_sensitive_string(#sensitive_string{}) -> true;
is_sensitive_string(_) -> false.

%% @doc Extract value from sensitive_string or binary/list
-spec extract_value(term()) -> binary() | undefined.
extract_value(#sensitive_string{value = Value}) ->
    Value;
extract_value(Value) when is_binary(Value) ->
    Value;
extract_value(Value) when is_list(Value) ->
    list_to_binary(Value);
extract_value(_) ->
    undefined.

%% @doc Extract value or error
-spec extract_required_value(term()) -> binary().
extract_required_value(Value) ->
    case extract_value(Value) of
        undefined -> error(badarg);
        Result -> Result
    end.

%% @doc Convert to sensitive_string if not already
-spec sensitive(term()) -> #sensitive_string{} | undefined.
sensitive(undefined) -> undefined;
sensitive(#sensitive_string{} = SS) -> SS;
sensitive(Value) when is_binary(Value) -> new(Value);
sensitive(Value) when is_list(Value) -> new(Value);
sensitive(Value) -> new(io_lib:format("~p", [Value])).

%%====================================================================
%% Internal functions
%%====================================================================

%% @private
%% Convert binary hash to hex string
-spec bin_to_hex(binary()) -> binary().
bin_to_hex(Bin) ->
    list_to_binary([io_lib:format("~2.16.0b", [X]) || <<X>> <= Bin]).

%%====================================================================
%% Unit tests
%%====================================================================

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

%% Basic creation and value access
new_test() ->
    SS = new(<<"my-secret">>),
    ?assert(is_sensitive_string(SS)),
    ?assertEqual(<<"my-secret">>, get_value(SS)).

new_from_list_test() ->
    SS = new("my-secret"),
    ?assertEqual(<<"my-secret">>, get_value(SS)).

%% to_string shows hash
to_string_test() ->
    SS = new(<<"my-secret">>),
    Result = to_string(SS),
    ?assert(binary:match(Result, <<"sha256:">>) =/= nomatch),
    ?assertEqual(nomatch, binary:match(Result, <<"my-secret">>)).

%% Consistent hash
consistent_hash_test() ->
    SS1 = new(<<"consistent">>),
    SS2 = new(<<"consistent">>),
    ?assertEqual(to_string(SS1), to_string(SS2)).

%% JSON encoding
to_json_test() ->
    SS = new(<<"secret123">>),
    Result = to_json(SS),
    ?assert(binary:match(Result, <<"sha256:">>) =/= nomatch),
    ?assertEqual(nomatch, binary:match(Result, <<"secret123">>)).

%% Type checking
is_sensitive_string_test() ->
    SS = new(<<"test">>),
    ?assert(is_sensitive_string(SS)),
    ?assertNot(is_sensitive_string(<<"plain">>)),
    ?assertNot(is_sensitive_string(undefined)).

%% Extract value
extract_value_test() ->
    SS = new(<<"secret">>),
    ?assertEqual(<<"secret">>, extract_value(SS)),
    ?assertEqual(<<"plain">>, extract_value(<<"plain">>)),
    ?assertEqual(<<"plain">>, extract_value("plain")),
    ?assertEqual(undefined, extract_value(undefined)).

%% Extract required value
extract_required_value_test() ->
    SS = new(<<"secret">>),
    ?assertEqual(<<"secret">>, extract_required_value(SS)),
    ?assertEqual(<<"plain">>, extract_required_value(<<"plain">>)),
    ?assertError(badarg, extract_required_value(undefined)).

%% Sensitive conversion
sensitive_test() ->
    SS = new(<<"original">>),
    ?assertEqual(SS, sensitive(SS)),
    Result = sensitive(<<"plain">>),
    ?assert(is_sensitive_string(Result)),
    ?assertEqual(<<"plain">>, get_value(Result)),
    ?assertEqual(undefined, sensitive(undefined)).

-endif.

