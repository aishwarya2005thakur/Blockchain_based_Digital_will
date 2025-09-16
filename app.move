module MyModule::DigitalWill {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a digital will with inheritance details.
    struct Will has store, key {
        testator: address,        // Address of the person creating the will
        beneficiary: address,     // Address of the inheritance beneficiary
        inheritance_amount: u64,  // Amount of APT tokens to inherit
        unlock_time: u64,         // Timestamp when inheritance can be claimed
        is_active: bool,          // Whether the will is active
        funds_deposited: u64,     // Total funds deposited for inheritance
    }

    /// Function to create a digital will with inheritance funds.
    public fun create_will(
        testator: &signer, 
        beneficiary: address, 
        inheritance_amount: u64, 
        unlock_time: u64
    ) {
        let testator_addr = signer::address_of(testator);
        
        // Deposit inheritance funds into the contract
        let inheritance_funds = coin::withdraw<AptosCoin>(testator, inheritance_amount);
        coin::deposit<AptosCoin>(testator_addr, inheritance_funds);
        
        let will = Will {
            testator: testator_addr,
            beneficiary,
            inheritance_amount,
            unlock_time,
            is_active: true,
            funds_deposited: inheritance_amount,
        };
        
        move_to(testator, will);
    }

    /// Function for beneficiary to claim inheritance after unlock time.
    public fun claim_inheritance(
        beneficiary: &signer, 
        testator_address: address
    ) acquires Will {
        let will = borrow_global_mut<Will>(testator_address);
        let beneficiary_addr = signer::address_of(beneficiary);
        let current_time = timestamp::now_seconds();
        
        // Verify beneficiary and timing conditions
        assert!(will.beneficiary == beneficiary_addr, 1);
        assert!(current_time >= will.unlock_time, 2);
        assert!(will.is_active, 3);
        
        // Transfer inheritance to beneficiary
        let inheritance = coin::withdraw<AptosCoin>(beneficiary, will.inheritance_amount);
        coin::deposit<AptosCoin>(beneficiary_addr, inheritance);
        
        // Mark will as inactive after claiming
        will.is_active = false;
    }
}