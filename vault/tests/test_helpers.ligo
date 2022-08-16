module TestHelpers is {
        // https://ligolang.org/docs/reference/test
    type deploy_result_t is address * typed_address(action_t, storage_t) * contract(action_t);
    type deploy_token_result_t is address * typed_address(TokenFA12.action_t, TokenFA12.storage_t) * contract(TokenFA12.action_t);

    function before_each(const _ : unit) is block {
		Test.reset_state(3n, (nil: list(tez)));
		Test.set_source(Test.nth_bootstrap_account(0))
	} with unit

    function deploy_vault_contract(const _ : unit): deploy_result_t is block {
        const initial_storage : storage_t = record [
            ledger = (big_map[] : big_map(address, user_account_t))
        ];
        const (contract_typed_address, _, _) = Test.originate(main, initial_storage, 0tez);
        const contract = Test.to_contract(contract_typed_address);
        const address = Tezos.address(contract)
    } with (address, contract_typed_address, contract)

    function deploy_test_fa12_token(
        const token_owner_address : address;
        const total_supply: nat
    ): deploy_token_result_t is block {
        const initial_storage : TokenFA12.storage_t = record [
            total_supply = total_supply;
            ledger = big_map[
                token_owner_address -> (record [
                    balance = total_supply;
                    allowances = map[];
                ] : TokenFA12.account_t)
            ]
        ];
        const (contract_typed_address, _, _) = Test.originate(TokenFA12.main, initial_storage, 0tez);
        const contract = Test.to_contract(contract_typed_address);
        const address = Tezos.address(contract)
    } with (address, contract_typed_address, contract)

	function get_token_balance(const token_address : typed_address(TokenFA12.action_t, TokenFA12.storage_t); const address : address): nat is {
		const token_storage = Test.get_storage(token_address);
		const account = token_storage.ledger[address];
		const balance = case account of [
			| Some(x) -> x.balance
			| None    -> 0n
		];
	} with balance
}
