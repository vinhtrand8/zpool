# ZPool

## How It Works

1. **User Deposits:** Users deposit token (`join_pool_public`) into the current active pool.
2. **Pool Rotation:** The admin closes the current pool and opens a new one (`close_pool_public`).
3. **Profit Generation & Winner Selection:** (`select_winner_public`)
   - When a pool generates a profit, the admin selects a winner from the closed pool.
   - The admin cannot immediately close a pool and select a winner because user deposits are transferred to **Pondo**, which charges a fee.
   - The admin must wait until the pool accumulates profits to ensure the winner receives a payout.
4. **Withdrawal Unlocking:** (`claim_withdrawal_public` on `Pondo` contract)
   - **Pondo** unlocks withdrawals at the start of a new Aleo epoch (which can take 2-5 days).
   - After that, anyone can call `Pondo` to claim the withdrawal for the `ZPool` contract, though it's recommended for the admin to handle this.
5. **User Redemption:** Once the withdrawal is claimed, users can redeem their deposited funds (`redeem_public`).

### Recommendations

- The waiting period between closing a pool and selecting a winner should be **5-7 days** to maximize profits.
- The admin should call `claim_withdrawal_public` on the `Pondo` contract before step 5 to facilitate withdrawals.

---

## Contract Functions

### Initialize Pool Contract

**Function:** `initialize_pool_public`

| Argument     | Type      | Description                   |
| ------------ | --------- | ----------------------------- |
| `init_admin` | `address` | Initial admin of the contract |

---

### Update Admin

**Function:** `update_admin_public`

- **Access Control:** Only the admin can call this function.

| Argument    | Type      | Description              |
| ----------- | --------- | ------------------------ |
| `new_admin` | `address` | Address of the new admin |

---

### Join Pool

**Function:** `join_pool_public`

| Argument              | Type  | Description                                                                                    |
| --------------------- | ----- | ---------------------------------------------------------------------------------------------- |
| `credits_deposit`     | `u64` | Amount of Aleo to deposit                                                                      |
| `expected_paleo_mint` | `u64` | Expected pAleo (since the contract cannot estimate this, the UI must provide a roughly number) |

---

### Close Pool

**Function:** `close_pool_public`

- **Access Control:** Only the admin can call this function.

---

### Select Winner

**Function:** `select_winner_public`

- **Access Control:** Only the admin can call this function.

| Argument            | Type  | Description                                            |
| ------------------- | ----- | ------------------------------------------------------ |
| `pool_id`           | `u64` | ID of the pool                                         |
| `paleo_burn_amount` | `u64` | Total pAleo in the pool (must match the stored amount) |

---

### Redeem Deposits

**Function:** `redeem_public`

| Argument         | Type      | Description                                                                            |
| ---------------- | --------- | -------------------------------------------------------------------------------------- |
| `pool_id`        | `u64`     | ID of the pool                                                                         |
| `player`         | `address` | Address of the player redeeming funds                                                  |
| `credits_redeem` | `u64`     | Deposited credits, and rewards if the caller is the winner (must match stored balance) |
