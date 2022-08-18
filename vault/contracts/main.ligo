#include "types.ligo"


function get_or_create_user_account(
    const user_address : address;
    const storage : storage_t
): user_account_t is
    case storage.ledger[user_address] of [
        | Some(x) -> x
        | None    -> record [ tez = 0tez; tokens = (map[] : map(token_address_t, nat)) ]
    ]


function get_or_default_token_balance(
    const token_contract_address : address;
    const user_account: user_account_t
) : nat is
    case user_account.tokens[token_contract_address] of [
        | None    -> 0n
        | Some(x) -> x
    ]


function deposit_tez(var storage : storage_t): return_t is {
    var user_account := get_or_create_user_account(Tezos.get_source(), storage);
    user_account.tez := user_account.tez + Tezos.get_amount();
    storage.ledger[Tezos.get_source()] := user_account;
} with ((list[]: list(operation)), storage)


function deposit_tokens(
    const token_params: token_params_t;
    var   storage : storage_t
): return_t is {
    const token_contract = token_params.token_address;

    var user_account := get_or_create_user_account(Tezos.get_source(), storage);
    const token_balance = get_or_default_token_balance(token_contract, user_account);
    user_account.tokens[token_contract] := token_balance + token_params.amount;

    const transfer_params: transfer_fa12_parameters_t = record [
        _from = Tezos.get_source();
        _to = Tezos.get_self_address();
        value = token_params.amount;
    ];

    const token_contract_transfer_entrypoint = Option.unopt(
        (Tezos.get_entrypoint_opt("%transfer", token_contract): option(contract(transfer_fa12_parameters_t)))
    );

    storage.ledger[Tezos.get_source()] := user_account;
    const operations = list[
        Tezos.transaction(transfer_params, 0tez, token_contract_transfer_entrypoint)
    ]
} with (operations, storage)


function deposit(
    const token_params : option(token_params_t);
    const storage : storage_t
): return_t is case token_params of [
    | None    -> deposit_tez(storage)
    | Some(x) -> deposit_tokens(x, storage)
]


function withdraw(
    const storage : storage_t
): return_t is block {
    var user_account := get_or_create_user_account(Tezos.get_source(), storage);

    var user_tez := user_account.tez;
    user_account.tez := 0;

    storage.ledger[Tezos.get_source()] := user_account;

    var operations : list(operation);
    if user_tez =/= 0 then {
        operations : list(operation) := list[
            Tezos.transaction(unit, user_tez, Tezos.get_source())
        ];
    }
} with (operations, storage)


function main (
    const action : action_t;
    const storage : storage_t
): return_t is case action of [
    | Deposit(params) -> deposit(params, storage)
    | Withdraw(_params) -> withdraw()
]
