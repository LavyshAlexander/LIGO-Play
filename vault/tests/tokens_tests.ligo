const test_deposit_tokens = {
    TestHelpers.before_each();

	const source_address = Test.nth_bootstrap_account(0);
    const (contract_address, contract_typed_address, contract) = TestHelpers.deploy_vault_contract();
	const (token_contract_address, token_contract_typed_address, _token_contract) = TestHelpers.deploy_test_fa12_token(source_address, 1_000_000n);

	// const initial_source_balance = Test.get_balance(source_address);
	// const initial_vault_balance = Test.get_balance(contract_address);
	const initial_source_balance = TestHelpers.get_token_balance(token_contract_typed_address, source_address);
	const initial_contract_balance = TestHelpers.get_token_balance(token_contract_typed_address, contract_address);

	const token_params: option(token_params_t) = Some(record [
		token_address = token_contract_address;
		amount = 500_000n;
	]);
    const consumed_gas = Test.transfer_to_contract_exn(contract, Deposit(token_params), 0tez);
	const storage = Test.get_storage(contract_typed_address);

	const result_contract_balance = TestHelpers.get_token_balance(token_contract_typed_address, contract_address);
	const result_source_balance = TestHelpers.get_token_balance(token_contract_typed_address, source_address);

	const account = Option.unopt(storage.ledger[source_address]);
	const tokens_balance = Option.unopt(account.tokens[token_contract_address]);


	assert_with_error(abs(initial_source_balance - result_source_balance) = 500_000n,
						"Incorrect value of source address balance");
	assert_with_error(abs(result_contract_balance - initial_contract_balance) = 500_000n,
						"Incorrect value of contract address balance");
	assert_with_error(tokens_balance = 500_000n, "Incorrect value of contract big_map");
} with (record [status = "OK"; consumed_gas = consumed_gas]);