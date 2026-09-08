from uuid import UUID


def calculate_settlement(
    contributions: dict[UUID, int],
    spent: dict[UUID, int],
    active_member_ids: set[UUID] | list[UUID] | None = None,
) -> dict[UUID, int]:
    """
    Calculate each member's net spending position.

    Positive = member contributed more than their expense share (CREDITOR).
    Negative = member's expense share is greater than their contribution (DEBTOR).
    Zero = member is fully settled.
    """
    member_ids = set(contributions) | set(spent)
    if active_member_ids:
        member_ids |= set(active_member_ids)

    settlement = {}

    for member_id in sorted(member_ids, key=lambda x: str(x)):
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

    members = sorted(contributions.keys(), key=lambda x: str(x))

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
    """
    Generate deterministic peer-to-peer settlement transfers from debtors to creditors.
    Requires sum(settlement.values()) == 0.
    """
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

    total_creditor_paise = sum(c["amount_paise"] for c in creditors)
    total_debtor_paise = sum(d["amount_paise"] for d in debtors)

    if total_creditor_paise != total_debtor_paise:
        raise ValueError(
            f"Settlement is not balanced: total creditors ({total_creditor_paise} paise) "
            f"does not equal total debtors ({total_debtor_paise} paise)"
        )

    # Sort largest amount first; break ties deterministically with UUID string
    creditors.sort(
        key=lambda x: (-x["amount_paise"], str(x["member_id"])),
    )
    debtors.sort(
        key=lambda x: (-x["amount_paise"], str(x["member_id"])),
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