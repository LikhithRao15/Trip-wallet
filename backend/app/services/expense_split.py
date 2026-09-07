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

    splits = {}

    for index, member_id in enumerate(member_ids):
        split_amount = base_amount

        if index < remainder:
            split_amount += 1

        splits[member_id] = split_amount

    return splits