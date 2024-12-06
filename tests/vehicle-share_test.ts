import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new vehicle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const vehicle = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('vehicle-share', 'register-vehicle',
                [types.principal(vehicle.address),
                 types.ascii("Tesla Model 3"),
                 types.uint(2023)],
                deployer.address
            )
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can transfer shares and check out vehicle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const vehicle = accounts.get('wallet_1')!;
        const user = accounts.get('wallet_2')!;
        
        // Register vehicle
        let block = chain.mineBlock([
            Tx.contractCall('vehicle-share', 'register-vehicle',
                [types.principal(vehicle.address),
                 types.ascii("Tesla Model 3"),
                 types.uint(2023)],
                deployer.address
            ),
            // Transfer 50% shares
            Tx.contractCall('vehicle-share', 'transfer-shares',
                [types.principal(vehicle.address),
                 types.principal(user.address),
                 types.uint(50)],
                deployer.address
            )
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectOk().expectBool(true);
        
        // Check out vehicle
        let checkoutBlock = chain.mineBlock([
            Tx.contractCall('vehicle-share', 'check-out-vehicle',
                [types.principal(vehicle.address)],
                user.address
            )
        ]);
        
        checkoutBlock.receipts[0].result.expectOk().expectBool(true);
    }
});
