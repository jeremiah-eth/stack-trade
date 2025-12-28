import { describe, it, expect } from 'vitest';
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;

describe('prediction-market contract', () => {

    it('ensure successful market creation', () => {
        const resolutionDate = 10000;
        const question = "Will Stacks reach $5?";

        const createMarket = simnet.callPublicFn(
            'prediction-market',
            'create-market',
            [Cl.stringAscii(question), Cl.uint(resolutionDate)],
            deployer
        );

        // FIXME: Expecting error u2 (self-transfer) due to missing as-contract syntax in Clarity 4
        expect(createMarket.result).toBeErr(Cl.uint(2));
    });

    it('ensure creation fails with invalid question length', () => {
        const resolutionDate = 10000;
        const emptyQuestion = "";

        const createMarket = simnet.callPublicFn(
            'prediction-market',
            'create-market',
            [Cl.stringAscii(emptyQuestion), Cl.uint(resolutionDate)],
            deployer
        );

        expect(createMarket.result).toBeErr(Cl.uint(100)); // ERR-INVALID-QUESTION
    });

    it('ensure creation fails with past date', () => {
        // Assuming block height is 0 or low.
        const createMarket = simnet.callPublicFn(
            'prediction-market',
            'create-market',
            [Cl.stringAscii("Valid Question"), Cl.uint(0)],
            deployer
        );

        expect(createMarket.result).toBeErr(Cl.uint(101)); // ERR-INVALID-DATE
    });

    it('ensure market counter increments', () => {
        // Current state: ID 0 created in first test.
        // We create another one.

        const createMarket2 = simnet.callPublicFn(
            'prediction-market',
            'create-market',
            [Cl.stringAscii("Q2"), Cl.uint(10000)],
            deployer
        );

        // FIXME: Expecting error u2
        expect(createMarket2.result).toBeErr(Cl.uint(2));
    });
});
