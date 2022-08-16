#include "types.ligo"

function get_or_create_user_account(const user_address : address; const storage : storage_t ): user_account_t is
    case storage.ledger[user_address] of [
        | Some(x) -> x
        | None    -> record [ tez = 0tez; tokens = (map[] : map(token_address_t, nat)) ]
    ]

function deposit_tez(var storage : storage_t): return_t is {
    var user_account := get_or_create_user_account(Tezos.get_source(), storage);
    user_account.tez := user_account.tez + Tezos.get_amount();
    storage.ledger[Tezos.get_source()] := user_account;
} with ((list[]: list(operation)), storage)


function deposit_tokens(const token_params: token_params_t; const storage : storage_t): return_t is {
    const token_contract = token_params.token_address;

    var user_account := get_or_create_user_account(Tezos.get_source(), storage);
    const token_balance = case user_account.tokens[token_contract] of [
        | None    -> 0n
        | Some(x) -> x
    ];
    user_account.tokens[token_contract] := token_balance + token_params.amount;
    
    const transfer_params: transfer_fa12_parameters_t = record [
        _from = Tezos.get_source();
        _to = Tezos.get_self_address();
        value = token_params.amount;
    ];
    const token_contract_entrypoint = Option.unopt(
        (Tezos.get_entrypoint_opt("%transfer", token_contract): option(contract(transfer_fa12_parameters_t)))
    );
    const operations = list[Tezos.transaction(transfer_params, 0tez, token_contract_entrypoint)]
} with (operations, storage)

function deposit(const token_params : option(token_params_t); const storage : storage_t): return_t is case token_params of [
    | None    -> deposit_tez(storage)
    | Some(x) -> deposit_tokens(x, storage)
]

function main(const action : action_t; const storage : storage_t): return_t is case action of [
    | Deposit(params) -> deposit(params, storage)
    | Withdraw(_params) -> failwith("Not implemented")
] 
