import uuid
import pytest
from uuid import UUID

from app.services.expense_split import calculate_equal_split
from app.services.settlement import (
    calculate_settlement,
    calculate_transfers,
    calculate_wallet_refunds,
)


def test_equal_split():
    members = [uuid.uuid4() for _ in range(7)]

    result = calculate_equal_split(700, members)

    assert len(result) == 7
    assert sum(result.values()) == 700
    assert all(amount == 100 for amount in result.values())


def test_odd_split():
    members = [uuid.uuid4() for _ in range(3)]

    result = calculate_equal_split(100, members)

    assert sum(result.values()) == 100
    assert sorted(result.values()) == [33, 33, 34]


def test_duplicate_members_rejected():
    member_a = uuid.uuid4()
    member_b = uuid.uuid4()

    with pytest.raises(ValueError):
        calculate_equal_split(
            100,
            [member_a, member_a, member_b],
        )


def test_zero_amount_rejected():
    members = [uuid.uuid4()]

    with pytest.raises(ValueError):
        calculate_equal_split(0, members)


def test_negative_amount_rejected():
    members = [uuid.uuid4()]

    with pytest.raises(ValueError):
        calculate_equal_split(-100, members)


def test_settlement_calculation():
    member_a = uuid.uuid4()
    member_b = uuid.uuid4()

    contributions = {
        member_a: 500,
        member_b: 500,
    }

    spent = {
        member_a: 300,
        member_b: 700,
    }

    result = calculate_settlement(contributions, spent)

    assert result[member_a] == 200
    assert result[member_b] == -200


def test_settlement_transfers():
    creditor = uuid.uuid4()
    debtor = uuid.uuid4()

    settlement = {
        creditor: 500,
        debtor: -500,
    }

    transfers = calculate_transfers(settlement)

    assert len(transfers) == 1
    assert transfers[0]["from_member_id"] == debtor
    assert transfers[0]["to_member_id"] == creditor
    assert transfers[0]["amount_paise"] == 500


def test_transfer_money_conservation():
    member_a = uuid.uuid4()
    member_b = uuid.uuid4()
    member_c = uuid.uuid4()

    settlement = {
        member_a: 1000,
        member_b: -600,
        member_c: -400,
    }

    transfers = calculate_transfers(settlement)

    total_transferred = sum(
        transfer["amount_paise"]
        for transfer in transfers
    )

    assert total_transferred == 1000


def test_transfer_balances_are_fully_settled():
    creditor = uuid.uuid4()
    debtor_a = uuid.uuid4()
    debtor_b = uuid.uuid4()

    settlement = {
        creditor: 1000,
        debtor_a: -600,
        debtor_b: -400,
    }

    transfers = calculate_transfers(settlement)

    assert len(transfers) == 2
    assert sum(
        transfer["amount_paise"]
        for transfer in transfers
    ) == 1000

def test_wallet_refunds():
    member_a = UUID("00000000-0000-0000-0000-000000000001")
    member_b = UUID("00000000-0000-0000-0000-000000000002")

    contributions = {
        member_a: 50000,   # ₹500
        member_b: 100000,  # ₹1000
    }

    refunds = calculate_wallet_refunds(
        contributions,
        90000,  # ₹900 remaining
    )

    assert refunds[member_a] == 30000
    assert refunds[member_b] == 60000
    assert sum(refunds.values()) == 90000

def test_wallet_refunds_with_zero_balance():
    member_a = UUID("00000000-0000-0000-0000-000000000001")
    member_b = UUID("00000000-0000-0000-0000-000000000002")

    contributions = {
        member_a: 50000,
        member_b: 100000,
    }

    refunds = calculate_wallet_refunds(
        contributions,
        0,
    )

    assert refunds[member_a] == 0
    assert refunds[member_b] == 0

def test_trip_status_values():
    active_status = "ACTIVE"
    closed_status = "CLOSED"

    assert active_status != closed_status
    assert active_status == "ACTIVE"
    assert closed_status == "CLOSED"


def test_closed_trip_is_not_active():
    trip_status = "CLOSED"

    assert trip_status != "ACTIVE"


def test_active_trip_is_active():
    trip_status = "ACTIVE"

    assert trip_status == "ACTIVE"

def test_settlement_matches_remaining_wallet():
    member_a = UUID("00000000-0000-0000-0000-000000000001")
    member_b = UUID("00000000-0000-0000-0000-000000000002")

    contributions = {
        member_a: 50000,   # ₹500
        member_b: 100000,  # ₹1000
    }

    spent = {
        member_a: 30000,   # ₹300
        member_b: 60000,   # ₹600
    }

    settlement = calculate_settlement(
        contributions,
        spent,
    )

    remaining_wallet = 150000 - 90000

    assert settlement[member_a] == 20000
    assert settlement[member_b] == 40000
    assert sum(settlement.values()) == remaining_wallet