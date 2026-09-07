from alembic import op


# revision identifiers, used by Alembic.
revision = "52ae6792c712"
down_revision = "92ba73beab5d"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_check_constraint(
        "ck_wallet_balance_non_negative",
        "wallets",
        "balance_paise >= 0",
    )

    op.create_check_constraint(
        "ck_contribution_amount_positive",
        "contributions",
        "amount_paise > 0",
    )

    op.create_check_constraint(
        "ck_expense_amount_positive",
        "expenses",
        "amount_paise > 0",
    )

    op.create_check_constraint(
        "ck_expense_split_amount_positive",
        "expense_splits",
        "amount_paise > 0",
    )


def downgrade() -> None:
    op.drop_constraint(
        "ck_expense_split_amount_positive",
        "expense_splits",
        type_="check",
    )

    op.drop_constraint(
        "ck_expense_amount_positive",
        "expenses",
        type_="check",
    )

    op.drop_constraint(
        "ck_contribution_amount_positive",
        "contributions",
        type_="check",
    )

    op.drop_constraint(
        "ck_wallet_balance_non_negative",
        "wallets",
        type_="check",
    )