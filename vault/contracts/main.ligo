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

function withdraw_tez(var storage : storage_t): return_t is {
    var user_account := get_or_create_user_account(Tezos.get_source(), storage);

    var user_tez := user_account.tez;
    user_account.tez := 0tez;

    storage.ledger[Tezos.get_source()] := user_account;

    var operations : list(operation) := nil;
    if user_tez =/= 0tez then {
        operations := list[
            Tezos.transaction(unit, user_tez, (Tezos.get_contract(Tezos.get_source()) : contract(unit)))
        ];
    }
} with (operations, storage)


function withdraw_tokens(
    const token_address : token_address_t;
    const amount  : option(nat);
    var   s       : storage_t
): return_t is {
    var user_account := get_or_create_user_account(Tezos.get_source(), s);
    const token_balance = get_or_default_token_balance(token_address, user_account);

    const withdraw_amount : nat = case amount of [
        | None    -> token_balance
        | Some(v) -> v
    ];
    if token_balance < withdraw_amount then failwith("NotEnoughtTokens");
    user_account.tokens[token_address] := abs(token_balance - withdraw_amount);

    const transfer_params: transfer_fa12_parameters_t = record [
        _from = Tezos.get_self_address();
        _to = Tezos.get_source();
        value = withdraw_amount;
    ];

    const token_transfer_entrypoint = Option.unopt(
        (Tezos.get_entrypoint_opt("%transfer", token_address): option(contract(transfer_fa12_parameters_t)))
    );

    s.ledger[Tezos.get_source()] := user_account;
    const operations = list[
        Tezos.transaction(transfer_params, 0tez, token_transfer_entrypoint)
    ]
} with (operations, s)


function withdraw(
    const params: option(withdraw_params_t);
    const storage : storage_t
): return_t is case params of [
    | None    -> withdraw_tez(storage)
    | Some(p) -> withdraw_tokens(p.token_address, p.amount, storage)
]


function main (
    const action : action_t;
    const storage : storage_t
): return_t is case action of [
    | Deposit(params) -> deposit(params, storage)
    | Withdraw(params) -> withdraw(params, storage)
]
