const test_deposit_tez = {
    TestHelpers.before_each();

    const (contract_address, contract_typed_address, contract) = TestHelpers.deploy_vault_contract();

	const source_address = Test.nth_bootstrap_account(0);

	const initial_source_balance = Test.get_balance(source_address);
	const initial_vault_balance = Test.get_balance(contract_address);

    const consumed_gas = Test.transfer_to_contract_exn(contract, Deposit((None: option(token_params_t))), 1500tez);
	const storage = Test.get_storage(contract_typed_address);

	const result_source_balance = Test.get_balance(source_address);
	const result_vault_balance = Test.get_balance(contract_address);
	const ledger_value = Option.unopt(storage.ledger[source_address]);

	assert_with_error(Option.unopt(initial_source_balance - result_source_balance) < 1500tez,
						"Incorrect value of source address balance");
	assert_with_error(Option.unopt(result_vault_balance - initial_vault_balance) = 1500tez,
						"Incorrect value of vault address balance");
	assert_with_error(ledger_value.tez = 1500tez, "Incorrect value of contract big_map");
} with (record [status = "OK"; consumed_gas = consumed_gas]);
