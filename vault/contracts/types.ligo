type token_address_t is address;
type user_account_t is record [
    tez: tez;
    tokens: map(token_address_t, nat);
]

type token_params_t is record [
    token_address: token_address_t;
    amount: nat;
]

type withdraw_params_t is record [
    token_address: option(token_address_t);
    amount: option(nat);
]

type storage_t is record [
    ledger: big_map(address, user_account_t);
]

type return_t is list(operation) * storage_t

type action_t is
    | Deposit of (option(token_params_t))
	| Withdraw of (option(withdraw_params_t))

type transfer_fa12_parameters_t is [@layout:comb] record [
    [@annot:from] _from: address;
    [@annot:to] _to: address;
    value: nat;
];

type approve_f12_parameters_t is [@layout:comb] record [
    spender: address;
    value: nat;
]
