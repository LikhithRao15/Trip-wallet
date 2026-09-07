def test_wallet_balance_formula():
    contributions = 150000
    expenses = 70000

    calculated_balance = contributions - expenses

    assert calculated_balance == 80000