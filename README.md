# ZPool

## Initialize pool contract

- Function: initialize_pool_public

- Arguments

  | name       | type    | description   |
  | ---------- | ------- | ------------- |
  | init_admin | address | Initial admin |

## Update admin

- Function: update_admin_public

- Note: Only admin can call this function

- Arguments

  | name      | type    | description |
  | --------- | ------- | ----------- |
  | new_admin | address | New admin   |

## Join pool

- Function: join_pool_public

- Arguments

  | name                | type | description    |
  | ------------------- | ---- | -------------- |
  | credits_deposit     | u64  | Aleo amount    |
  | expected_paleo_mint | u64  | Expected pAleo |

## Close pool

- Function: close_pool_public

- Note: Only admin can call this function

## Select winner

- Function: select_winner_public

- Note: Only admin can call this function

- Arguments

  | name              | type | description              |
  | ----------------- | ---- | ------------------------ |
  | pool_id           | u64  | Pool Id                  |
  | paleo_burn_amount | u64  | total pAleo of this pool |

## Redeem

- Function: redeem_public
- Arguments

  | name           | type    | description                    |
  | -------------- | ------- | ------------------------------ |
  | pool_id        | u64     | Pool Id                        |
  | player         | address | Player                         |
  | credits_redeem | u64     | Deposited credits to this pool |
