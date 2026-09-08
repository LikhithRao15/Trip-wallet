from decimal import Decimal
from uuid import UUID


def calculate_equal_split(
    amount_paise: int,
    member_ids: list[UUID],
) -> dict[UUID, int]:
    if amount_paise <= 0:
        raise ValueError("Amount must be greater than zero")

    if not member_ids:
        raise ValueError("At least one member is required")

    if len(member_ids) != len(set(member_ids)):
        raise ValueError("Duplicate members are not allowed")

    base_amount = amount_paise // len(member_ids)
    remainder = amount_paise % len(member_ids)

    splits: dict[UUID, int] = {}

    for index, member_id in enumerate(member_ids):
        split_amount = base_amount
        if index < remainder:
            split_amount += 1

        splits[member_id] = split_amount

    return splits


def calculate_custom_split(
    amount_paise: int,
    custom_splits: list[tuple[UUID, int]] | dict[UUID, int],
) -> dict[UUID, int]:
    if amount_paise <= 0:
        raise ValueError("Amount must be greater than zero")

    items = (
        list(custom_splits.items())
        if isinstance(custom_splits, dict)
        else list(custom_splits)
    )

    if not items:
        raise ValueError("At least one member split is required")

    member_ids = [m[0] for m in items]
    if len(member_ids) != len(set(member_ids)):
        raise ValueError("Duplicate members are not allowed")

    total_allocated = 0
    splits: dict[UUID, int] = {}

    for member_id, share in items:
        if share is None or share <= 0:
            raise ValueError(f"Share for member {member_id} must be greater than zero")
        splits[member_id] = int(share)
        total_allocated += int(share)

    if total_allocated < amount_paise:
        raise ValueError(
            f"Under-allocation: sum of custom shares ({total_allocated}) is less than expense amount ({amount_paise})"
        )
    if total_allocated > amount_paise:
        raise ValueError(
            f"Over-allocation: sum of custom shares ({total_allocated}) is greater than expense amount ({amount_paise})"
        )

    return splits


def calculate_percentage_split(
    amount_paise: int,
    percentage_splits: list[tuple[UUID, Decimal | str | float]] | dict[UUID, Decimal | str | float],
) -> dict[UUID, int]:
    if amount_paise <= 0:
        raise ValueError("Amount must be greater than zero")

    items = (
        list(percentage_splits.items())
        if isinstance(percentage_splits, dict)
        else list(percentage_splits)
    )

    if not items:
        raise ValueError("At least one member split is required")

    member_ids = [m[0] for m in items]
    if len(member_ids) != len(set(member_ids)):
        raise ValueError("Duplicate members are not allowed")

    parsed_items: list[tuple[UUID, Decimal]] = []
    total_pct = Decimal("0")

    for member_id, pct_val in items:
        if pct_val is None:
            raise ValueError(f"Percentage for member {member_id} is required")

        pct = Decimal(str(pct_val))
        if pct <= Decimal("0"):
            raise ValueError(f"Percentage for member {member_id} must be greater than zero")

        parsed_items.append((member_id, pct))
        total_pct += pct

    if total_pct < Decimal("100"):
        raise ValueError(
            f"Under-allocation: total percentage ({total_pct}%) is less than 100%"
        )
    if total_pct > Decimal("100"):
        raise ValueError(
            f"Over-allocation: total percentage ({total_pct}%) is greater than 100%"
        )

    base_shares: dict[UUID, int] = {}
    fractions: list[tuple[Decimal, int, UUID]] = []

    amount_dec = Decimal(amount_paise)
    allocated_sum = 0

    for idx, (member_id, pct) in enumerate(parsed_items):
        raw = (amount_dec * pct) / Decimal("100")
        base = int(raw)
        fraction = raw - Decimal(base)

        base_shares[member_id] = base
        allocated_sum += base
        fractions.append((fraction, idx, member_id))

    remainder = amount_paise - allocated_sum

    # Distribute remainder deterministically using largest remainder method
    fractions.sort(key=lambda x: (x[0], -x[1]), reverse=True)

    for i in range(remainder):
        target_member = fractions[i][2]
        base_shares[target_member] += 1

    for member_id, share in base_shares.items():
        if share <= 0:
            raise ValueError(f"Calculated share for member {member_id} must be greater than zero")

    return base_shares