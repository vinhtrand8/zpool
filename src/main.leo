import credits.aleo;
import pondo_protocol.aleo;
import token_registry.aleo;

program zpool_test_1.aleo {
    const PALEO_TOKEN_ID: field = 1751493913335802797273486270793650302076377624243810059080883537084141842600field;

    struct Pool {
        pool_id: u64,
        total_credits: u64,
        total_paleo: u64,
        total_players: u64,
        reward: u64,
        redeem_block: u32,
        closed: bool,
    }

    struct PlayerPool {
        player: address,
        pool_id: u64,
    }

    struct PlayerSlot {
        pool_id: u64,
        player_id: u64,
    }

    struct withdrawal_state {
        microcredits: u64,
        claim_block: u32
    }

    const DEFAULT_KEY: u8 = 0u8;
    
    mapping initialized: u8 => bool;
    mapping admin: u8 => address;
    
    mapping opened_pools: u64 => bool;
    mapping pools: u64 => Pool;
    mapping balances: field => u64;
    mapping player_slots: field => address;
    mapping pool_winner: u64 => address;

    async transition initialize(public init_admin: address) -> Future {
        return finalize_initialize(init_admin);
    }

    async function finalize_initialize(public init_admin: address) {
        let is_initialized: bool = initialized.get_or_use(DEFAULT_KEY, false);
        assert(!is_initialized);

        admin.set(DEFAULT_KEY, init_admin);
        
        initialized.set(DEFAULT_KEY, true);
    }

    async transition open_pool_public(
        public pool_id: u64
    ) -> Future {
        return finalize_open_pool_public(pool_id, self.caller);
    }

    async function finalize_open_pool_public(
        public pool_id: u64,
        public caller: address
    ) {
        assert(caller == admin.get(DEFAULT_KEY));

        let opened: bool = opened_pools.get_or_use(pool_id, false);
        assert(!opened);
        opened_pools.set(pool_id, true);

        let new_pool: Pool = Pool {
            pool_id: pool_id,
            total_credits: 0u64,
            total_paleo: 0u64,
            total_players: 0u64,
            reward: 0u64,
            redeem_block: 0u32,
            closed: false
        };
        pools.set(pool_id, new_pool);
    }

    async transition join_pool_public(
        public pool_id: u64,
        public credits_deposit: u64,
        public expected_paleo_mint: u64
    ) -> Future {
        // deposit credits
        let f0: Future = pondo_protocol.aleo/deposit_public_as_signer(credits_deposit, expected_paleo_mint, self.address);
        let f1: Future = token_registry.aleo/transfer_public_as_signer(PALEO_TOKEN_ID, self.address, expected_paleo_mint as u128);

        return finalize_join_pool_public(f0, f1, pool_id, self.signer, credits_deposit, expected_paleo_mint);
    }

    async function finalize_join_pool_public(
        public f0: Future,
        public f1: Future,
        public pool_id: u64,
        public player: address,
        public credits_deposit: u64,
        public expected_paleo_mint: u64
    ) {
        f0.await();
        f1.await();

        let current_pool: Pool = pools.get(pool_id);

        assert(!current_pool.closed);

        let player_pool: PlayerPool = PlayerPool {
            player: player,
            pool_id: pool_id
        };
        let player_pool_hash: field = BHP256::hash_to_field(player_pool);
        let player_balance: u64 = balances.get_or_use(player_pool_hash, 0u64);
        let new_player_balance: u64 = player_balance + credits_deposit;
        balances.set(player_pool_hash, new_player_balance);

        let player_slot: PlayerSlot = PlayerSlot {
            pool_id: pool_id,
            player_id: current_pool.total_players
        };
        let player_slot_hash: field = BHP256::hash_to_field(player_slot);
        player_slots.set(player_slot_hash, player);

        let new_pool: Pool = Pool {
            pool_id: pool_id,
            total_credits: current_pool.total_credits + credits_deposit as u64,
            total_paleo: current_pool.total_paleo + expected_paleo_mint as u64,
            total_players: current_pool.total_players + 1u64,
            reward: 0u64,
            redeem_block: 0u32,
            closed: false
        };
        pools.set(pool_id, new_pool);
    }

    async transition close_pool_public(
        public pool_id: u64,
    ) -> Future {
        return finalize_close_pool_public(pool_id, self.caller);
    }

     async function finalize_close_pool_public(
        public pool_id: u64,
        public caller: address,
    ) {
        assert(caller == admin.get(DEFAULT_KEY));

        let opened: bool = opened_pools.get(pool_id);
        assert(opened);

        let current_pool: Pool = pools.get(pool_id);
        assert(!current_pool.closed);

        let closed_pool: Pool = Pool {
            pool_id: current_pool.pool_id,
            total_credits: current_pool.total_credits,
            total_paleo: current_pool.total_paleo,
            total_players: current_pool.total_players,
            reward: current_pool.reward,
            redeem_block: current_pool.redeem_block,
            closed: true
        };
        pools.set(current_pool.pool_id, closed_pool);

        let new_pool: Pool = Pool {
            pool_id: current_pool.pool_id + 1u64,
            total_credits: 0u64,
            total_paleo: 0u64,
            total_players: 0u64,
            reward: 0u64,
            redeem_block: 0u32,
            closed: false
        };
        pools.set(new_pool.pool_id, new_pool);
    }

    async transition select_winner_public(
        public pool_id: u64,
        public paleo_burn_amount: u64
    ) -> Future {
        // call withdraw paleo
        let f0: Future = pondo_protocol.aleo/withdraw_public(paleo_burn_amount);

        return finalize_select_winner_public(f0, pool_id, self.caller, paleo_burn_amount);
    }

    async function finalize_select_winner_public(
        public f0: Future,
        public pool_id: u64,
        public caller: address,
        public paleo_burn_amount: u64
    ) {
        f0.await();

        assert(caller == admin.get(DEFAULT_KEY));

        let random_number: u64 = ChaCha::rand_u64();
        let current_pool: Pool = pools.get(pool_id);

        assert(current_pool.closed && current_pool.redeem_block == 0u32);
        assert(current_pool.total_paleo == paleo_burn_amount);

        let winner_slot: PlayerSlot = PlayerSlot {
            pool_id: pool_id,
            player_id: random_number % current_pool.total_players
        };
        let winner_slot_hash: field = BHP256::hash_to_field(winner_slot);
        let winner: address = player_slots.get(winner_slot_hash);
        pool_winner.set(pool_id, winner);

        let withdrawal: withdrawal_state = pondo_protocol.aleo/withdrawals.get(self.address);

        assert(withdrawal.microcredits > current_pool.total_credits);
        let reward: u64 = withdrawal.microcredits - current_pool.total_credits;

        let new_pool: Pool = Pool {
            pool_id: current_pool.pool_id,
            total_credits: current_pool.total_credits,
            total_paleo: current_pool.total_paleo,
            total_players: current_pool.total_players,
            reward: reward,
            redeem_block: withdrawal.claim_block,
            closed: true
        };
        pools.set(current_pool.pool_id, new_pool);
    }

    async transition redeem_public(
        public pool_id: u64,
        public player: address,
        public credits_redeem: u64,
    ) -> Future {
        // call withdraw paleo
        let f0: Future = credits.aleo/transfer_public(player, credits_redeem);

        return finalize_redeem_public(f0, pool_id, player, credits_redeem);
    }

    async function finalize_redeem_public(
        public f0: Future, 
        public pool_id: u64,
        public player: address,
        public credits_redeem: u64,
    ) {
        f0.await();

        let current_pool: Pool = pools.get(pool_id);
        assert(current_pool.closed);
        assert(current_pool.redeem_block != 0u32 && block.height >= current_pool.redeem_block);
        
        let player_pool: PlayerPool = PlayerPool {
            player: player,
            pool_id: pool_id
        };
        let player_pool_hash: field = BHP256::hash_to_field(player_pool);
        let deposit_amount: u64 = balances.get(player_pool_hash);

        let winner: address = pool_winner.get(pool_id);
        if player == winner {
            let reward: u64 = current_pool.reward;
            assert(credits_redeem == deposit_amount + reward);
        } else {
            assert(credits_redeem == deposit_amount);
        }

        balances.set(player_pool_hash, 0u64);
    }

    async transition update_admin_public(public new_admin: address) -> Future {
        return finalize_update_admin_public(self.caller, new_admin);
    }

    async function finalize_update_admin_public(
        public caller: address, 
        public new_admin: address
    ) {
        assert(caller == admin.get(DEFAULT_KEY));
        admin.set(DEFAULT_KEY, new_admin);
    }
}