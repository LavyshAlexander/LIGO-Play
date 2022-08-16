module TokenFA12 is {

type account_t is record [
    balance         : nat;
    allowances      : map(address, nat);
]

type storage_t is record [
  total_supply  : nat;
  ledger        : big_map(address, account_t);
]

type transfer_params_t is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")
type approve_params_t is address * nat //michelson_pair(address, "spender", nat, "value")
type balance_params_t is michelson_pair(address, "owner", contract(nat), "")
type allowance_params_t is michelson_pair(michelson_pair(address, "owner", address, "spender"), "", contract(nat), "")
type total_supply_params_t is (unit * contract(nat))

type return_t is list (operation) * storage_t

type action_t is
    | Transfer        of transfer_params_t
    | Approve         of approve_params_t
    | GetBalance      of balance_params_t
    | GetAllowance    of allowance_params_t
    | GetTotalSupply  of total_supply_params_t

function getAccount(const addr : address; const s : storage_t) : account_t is
    case s.ledger[addr] of [
      None ->  record [
        balance    = 0n;
        allowances = (map [] : map (address, nat));
      ]
    | Some(instance) -> instance
    ];

(* Helper function to get allowance for an account *)
function getAllowance (const ownerAccount : account_t; const spender : address; const _s : storage_t) : nat is
  case ownerAccount.allowances[spender] of [
    Some (nat) -> nat
  | None -> 0n
  ];

(* Transfer token to another account *)
function transfer (const from_ : address; const to_ : address; const value : nat; var s : storage_t) : return_t is
    block {
      (* Sending to yourself? *)
      if from_ = to_ then
        failwith("InvalidSelfToSelfTransfer")
      else skip;

      (* Retrieve sender account from storage *)
      var senderAccount : account_t := getAccount(from_, s);

      (* Balance check *)
      if senderAccount.balance < value then
        failwith("NotEnoughBalance")
      else skip;

      (* Check this address can spend the tokens *)
      if from_ =/= Tezos.get_sender() then block {
        const spenderAllowance : nat = getAllowance(senderAccount, Tezos.get_sender(), s);

        // if spenderAllowance < value then
        //   failwith("NotEnoughAllowance")
        // else skip;

        (* Decrease any allowances *)
        senderAccount.allowances[Tezos.get_sender()] := abs(spenderAllowance - value);
      } else skip;

      (* Update sender balance *)
      senderAccount.balance := abs(senderAccount.balance - value);

      (* Update storage *)
      s.ledger[from_] := senderAccount;

      (* Create or get destination account *)
      var destAccount : account_t := getAccount(to_, s);

      (* Update destination balance *)
      destAccount.balance := destAccount.balance + value;

      (* Update storage *)
      s.ledger[to_] := destAccount;

    } with ((nil: list(operation)), s)

  (* Approve an nat to be spent by another address in the name of [ the sender *)
  function approve (const spender : address; const value : nat; var s : storage_t) : return_t is
    block {
      if spender = Tezos.get_sender() then
        failwith("InvalidSelfToSelfApproval")
      else skip;

      (* Create or get sender account *)
      var senderAccount : account_t := getAccount(Tezos.get_sender(), s);

      (* Get current spender allowance *)
      const spenderAllowance : nat = getAllowance(senderAccount, spender, s);

      (* Prevent a corresponding attack vector *)
      if spenderAllowance > 0n and value > 0n then
        failwith("UnsafeAllowanceChange")
      else skip;

      (* Set spender allowance *)
      senderAccount.allowances[spender] := value;

      (* Update storage *)
      s.ledger[Tezos.get_sender()] := senderAccount;

    } with ((nil: list(operation)), s)

  (* View function that forwards the balance of [ source to a contract *)
  function getBalance (const owner : address; const contr : contract(nat); var s : storage_t) : return_t is
    block {
      const ownerAccount : account_t = getAccount(owner, s);
    } with (list [Tezos.transaction(ownerAccount.balance, 0tz, contr)], s)

  (* View function that forwards the allowance nat of [ spender in the name of [ tokenOwner to a contract *)
  function getAllowances (const owner : address; const spender : address; const contr : contract(nat); var s : storage_t) : return_t is
    block {
      const ownerAccount : account_t = getAccount(owner, s);
      const spenderAllowance : nat = getAllowance(ownerAccount, spender, s);
    } with (list [Tezos.transaction(spenderAllowance, 0tz, contr)], s)

  (* View function that forwards the totalSupply to a contract *)
  function getTotalSupply (const contr : contract(nat); var s : storage_t) : return_t is
    block {
      skip
    } with (list [Tezos.transaction(s.total_supply, 0tz, contr)], s)

function main(const action : action_t; var s : storage_t) : return_t is case action of [
      | Transfer(params)        -> transfer(params.0, params.1.0, params.1.1, s)
      | Approve(params)         -> approve(params.0, params.1, s)
      | GetBalance(params)      -> getBalance(params.0, params.1, s)
      | GetAllowance(params)    -> getAllowances(params.0.0, params.0.1, params.1, s)
      | GetTotalSupply(params)  -> getTotalSupply(params.1, s)
    ];
}
