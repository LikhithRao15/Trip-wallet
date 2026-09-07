from uuid import UUID


def calculate_settlement(
    contributions: dict[UUID, int],
    spent: dict[UUID, int],
) -> dict[UUID, int]:
    """
    Calculate each member's net spending position.

    Positive = member contributed more than their expense share.
    Negative = member's expense share is greater than their contribution.
    """
    member_ids = set(contributions) | set(spent)

    settlement = {}

    for member_id in member_ids:
        contributed = contributions.get(member_id, 0)
        consumed = spent.get(member_id, 0)

        settlement[member_id] = contributed - consumed

    return settlement


def calculate_wallet_refunds(
    contributions: dict[UUID, int],
    remaining_wallet_paise: int,
) -> dict[UUID, int]:
    """
    Distribute the remaining common-wallet balance proportionally
    according to each member's contribution.

    Example:
        A contributes ₹500
        B contributes ₹1,000
        Remaining wallet = ₹900

        A refund = ₹300
        B refund = ₹600
    """

    if remaining_wallet_paise < 0:
        raise ValueError("Remaining wallet balance cannot be negative")

    total_contributions = sum(contributions.values())

    if total_contributions == 0:
        if remaining_wallet_paise != 0:
            raise ValueError(
                "Cannot distribute wallet balance without contributions"
            )
        return {member_id: 0 for member_id in contributions}

    refunds = {}
    allocated = 0

    members = list(contributions.keys())

    for index, member_id in enumerate(members):
        contributed = contributions[member_id]

        if index == len(members) - 1:
            refund = remaining_wallet_paise - allocated
        else:
            refund = (
                remaining_wallet_paise * contributed
            ) // total_contributions

        refunds[member_id] = refund
        allocated += refund

    return refunds


def calculate_transfers(
    settlement: dict[UUID, int],
) -> list[dict]:
    creditors = []
    debtors = []

    for member_id, amount in settlement.items():
        if amount > 0:
            creditors.append({
                "member_id": member_id,
                "amount_paise": amount,
            })

        elif amount < 0:
            debtors.append({
                "member_id": member_id,
                "amount_paise": -amount,
            })

    creditors.sort(
        key=lambda x: x["amount_paise"],
        reverse=True,
    )

    debtors.sort(
        key=lambda x: x["amount_paise"],
        reverse=True,
    )

    transfers = []

    creditor_index = 0
    debtor_index = 0

    while (
        creditor_index < len(creditors)
        and debtor_index < len(debtors)
    ):
        creditor = creditors[creditor_index]
        debtor = debtors[debtor_index]

        transfer_amount = min(
            creditor["amount_paise"],
            debtor["amount_paise"],
        )

        transfers.append({
            "from_member_id": debtor["member_id"],
            "to_member_id": creditor["member_id"],
            "amount_paise": transfer_amount,
        })

        creditor["amount_paise"] -= transfer_amount
        debtor["amount_paise"] -= transfer_amount

        if creditor["amount_paise"] == 0:
            creditor_index += 1

        if debtor["amount_paise"] == 0:
            debtor_index += 1

    return transfers