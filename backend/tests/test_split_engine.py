from decimal import Decimal
import uuid
import pytest

from app.services.expense_split import (
    calculate_equal_split,
    calculate_custom_split,
    calculate_percentage_split,
)


def test_equal_split_cases():
    u1, u2, u3, u4, u5, u6, u7 = [uuid.uuid4() for _ in range(7)]

    # 1. 100 rupees (10000 paise) / 3 members
    s1 = calculate_equal_split(10000, [u1, u2, u3])
    assert s1 == {u1: 3334, u2: 3333, u3: 3333}
    assert sum(s1.values()) == 10000

    # 2. 700 rupees (70000 paise) / 4 members
    s2 = calculate_equal_split(70000, [u1, u2, u3, u4])
    assert s2 == {u1: 17500, u2: 17500, u3: 17500, u4: 17500}
    assert sum(s2.values()) == 70000

    # 3. 1 rupee (100 paise) / 3 members
    s3 = calculate_equal_split(100, [u1, u2, u3])
    assert s3 == {u1: 34, u2: 33, u3: 33}
    assert sum(s3.values()) == 100

    # 4. 999 rupees (99900 paise) / 7 members
    s4 = calculate_equal_split(99900, [u1, u2, u3, u4, u5, u6, u7])
    assert sum(s4.values()) == 99900
    assert max(s4.values()) - min(s4.values()) <= 1

    # 5. Large amount: 10,000,000 rupees (1,000,000,000 paise) / 3 members
    s5 = calculate_equal_split(1000000000, [u1, u2, u3])
    assert sum(s5.values()) == 1000000000
    assert s5[u1] == 333333334
    assert s5[u2] == 333333333
    assert s5[u3] == 333333333

    # Error cases
    with pytest.raises(ValueError, match="Amount must be greater than zero"):
        calculate_equal_split(0, [u1, u2])

    with pytest.raises(ValueError, match="Amount must be greater than zero"):
        calculate_equal_split(-500, [u1, u2])

    with pytest.raises(ValueError, match="At least one member is required"):
        calculate_equal_split(1000, [])

    with pytest.raises(ValueError, match="Duplicate members are not allowed"):
        calculate_equal_split(1000, [u1, u1])


def test_custom_split_cases():
    u1, u2, u3 = [uuid.uuid4() for _ in range(3)]

    # 1. Exact allocation: ₹700 (70000 paise) -> ₹200 (20000), ₹150 (15000), ₹350 (35000)
    splits = calculate_custom_split(70000, [(u1, 20000), (u2, 15000), (u3, 35000)])
    assert splits == {u1: 20000, u2: 15000, u3: 35000}
    assert sum(splits.values()) == 70000

    # 2. Under-allocation rejected
    with pytest.raises(ValueError, match="Under-allocation"):
        calculate_custom_split(70000, [(u1, 20000), (u2, 15000), (u3, 30000)])

    # 3. Over-allocation rejected
    with pytest.raises(ValueError, match="Over-allocation"):
        calculate_custom_split(70000, [(u1, 20000), (u2, 15000), (u3, 40000)])

    # 4. Zero share rejected
    with pytest.raises(ValueError, match="must be greater than zero"):
        calculate_custom_split(70000, [(u1, 70000), (u2, 0)])

    # 5. Negative share rejected
    with pytest.raises(ValueError, match="must be greater than zero"):
        calculate_custom_split(70000, [(u1, 80000), (u2, -10000)])

    # 6. Duplicate members rejected
    with pytest.raises(ValueError, match="Duplicate members are not allowed"):
        calculate_custom_split(70000, [(u1, 35000), (u1, 35000)])


def test_percentage_split_cases():
    u1, u2, u3 = [uuid.uuid4() for _ in range(3)]

    # 1. 50%, 30%, 20% on ₹700 (70000 paise)
    s1 = calculate_percentage_split(70000, [
        (u1, Decimal("50")),
        (u2, Decimal("30")),
        (u3, Decimal("20")),
    ])
    assert s1 == {u1: 35000, u2: 21000, u3: 14000}
    assert sum(s1.values()) == 70000

    # 2. Rounding case: 33.34%, 33.33%, 33.33% on ₹100 (10000 paise)
    s2 = calculate_percentage_split(10000, [
        (u1, Decimal("33.34")),
        (u2, Decimal("33.33")),
        (u3, Decimal("33.33")),
    ])
    assert s2 == {u1: 3334, u2: 3333, u3: 3333}
    assert sum(s2.values()) == 10000

    # 3. Rounding case on ₹1 (100 paise) with 33.34%, 33.33%, 33.33%
    s3 = calculate_percentage_split(100, [
        (u1, Decimal("33.34")),
        (u2, Decimal("33.33")),
        (u3, Decimal("33.33")),
    ])
    assert s3 == {u1: 34, u2: 33, u3: 33}
    assert sum(s3.values()) == 100

    # 4. Total < 100 rejected
    with pytest.raises(ValueError, match="Under-allocation"):
        calculate_percentage_split(10000, [
            (u1, Decimal("50")),
            (u2, Decimal("40")),
        ])

    # 5. Total > 100 rejected
    with pytest.raises(ValueError, match="Over-allocation"):
        calculate_percentage_split(10000, [
            (u1, Decimal("60")),
            (u2, Decimal("50")),
        ])

    # 6. Zero percentage rejected
    with pytest.raises(ValueError, match="must be greater than zero"):
        calculate_percentage_split(10000, [
            (u1, Decimal("100")),
            (u2, Decimal("0")),
        ])

    # 7. Negative percentage rejected
    with pytest.raises(ValueError, match="must be greater than zero"):
        calculate_percentage_split(10000, [
            (u1, Decimal("110")),
            (u2, Decimal("-10")),
        ])

    # 8. Duplicate members rejected
    with pytest.raises(ValueError, match="Duplicate members are not allowed"):
        calculate_percentage_split(10000, [
            (u1, Decimal("50")),
            (u1, Decimal("50")),
        ])
