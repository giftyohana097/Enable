
import { describe, expect, it, beforeEach } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const user1 = accounts.get("wallet_1")!;
const user2 = accounts.get("wallet_2")!;
const provider1 = accounts.get("wallet_3")!;

describe("Enable Smart Contract Tests", () => {
  it("should allow contract owner to register new users", () => {
    const { result } = simnet.callPublicFn(
      "Enable",
      "register-user",
      [
        Cl.principal(user1),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("active"),
        Cl.uint(1000), // expiration block
        Cl.uint(3), // priority level
        Cl.stringAscii("wheelchair user")
      ],
      deployer
    );
    expect(result).toBeOk(Cl.bool(true));
  });

  it("should fail when non-owner tries to register users", () => {
    const { result } = simnet.callPublicFn(
      "Enable",
      "register-user",
      [
        Cl.principal(user2),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("active"),
        Cl.uint(1000),
        Cl.uint(3),
        Cl.stringAscii("wheelchair user")
      ],
      user1 // Non-owner trying to register
    );
    expect(result).toBeErr(Cl.uint(100)); // err-owner-only
  });

  it("should allow service provider registration", () => {
    const { result } = simnet.callPublicFn(
      "Enable",
      "register-service-provider",
      [
        Cl.stringAscii("AccessCare Services"),
        Cl.stringAscii("mobility assistance, transportation")
      ],
      provider1
    );
    expect(result).toBeOk(Cl.bool(true));
  });

  it("should retrieve user details correctly", () => {
    // First register a user
    simnet.callPublicFn(
      "Enable",
      "register-user",
      [
        Cl.principal(user1),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("active"),
        Cl.uint(1000),
        Cl.uint(3),
        Cl.stringAscii("wheelchair user")
      ],
      deployer
    );

    const { result } = simnet.callReadOnlyFn(
      "Enable",
      "get-user-details",
      [Cl.principal(user1)],
      deployer
    );
    expect(result).toBeOk(
      Cl.tuple({
        "token-id": Cl.uint(1),
        "disability-type": Cl.stringAscii("mobility"),
        status: Cl.stringAscii("active"),
        expiration: Cl.uint(1000),
        "priority-level": Cl.uint(3),
        "verification-authority": Cl.principal(deployer),
        notes: Cl.stringAscii("wheelchair user")
      })
    );
  });

  it("should check if user is active correctly", () => {
    // Register user with future expiration  
    simnet.callPublicFn(
      "Enable",
      "register-user",
      [
        Cl.principal(user2),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("active"),
        Cl.uint(999999), // Far future expiration
        Cl.uint(3),
        Cl.stringAscii("wheelchair user")
      ],
      deployer
    );

    const { result } = simnet.callReadOnlyFn(
      "Enable",
      "is-active-user",
      [Cl.principal(user2)],
      deployer
    );
    expect(result).toBeOk(Cl.bool(true));
  });

  it("should return appropriate error for non-existent users", () => {
    const nonExistentUser = accounts.get("wallet_5")!;
    const { result } = simnet.callReadOnlyFn(
      "Enable",
      "get-user-details",
      [Cl.principal(nonExistentUser)],
      deployer
    );
    expect(result).toBeErr(Cl.uint(102)); // err-not-registered
  });

  it("should allow registered user to register equipment for lending", () => {
    // First register user
    simnet.callPublicFn(
      "Enable",
      "register-user",
      [
        Cl.principal(user1),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("active"),
        Cl.uint(999999),
        Cl.uint(3),
        Cl.stringAscii("wheelchair user")
      ],
      deployer
    );

    const { result } = simnet.callPublicFn(
      "Enable",
      "register-equipment",
      [
        Cl.stringAscii("Wheelchair"),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("Standard manual wheelchair"),
        Cl.stringAscii("excellent"),
        Cl.uint(50), // daily rate
        Cl.uint(200), // deposit
        Cl.stringAscii("Regular maintenance, clean condition")
      ],
      user1
    );
    expect(result).toBeOk(Cl.bool(true));
  });

  it("should calculate loan costs correctly", () => {
    // First register user and equipment
    simnet.callPublicFn(
      "Enable",
      "register-user",
      [
        Cl.principal(user1),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("active"),
        Cl.uint(999999),
        Cl.uint(3),
        Cl.stringAscii("wheelchair user")
      ],
      deployer
    );
    
    simnet.callPublicFn(
      "Enable",
      "register-equipment",
      [
        Cl.stringAscii("Wheelchair"),
        Cl.stringAscii("mobility"),
        Cl.stringAscii("Standard manual wheelchair"),
        Cl.stringAscii("excellent"),
        Cl.uint(50), // daily rate
        Cl.uint(200),
        Cl.stringAscii("Regular maintenance, clean condition")
      ],
      user1
    );

    const { result } = simnet.callReadOnlyFn(
      "Enable",
      "calculate-loan-cost",
      [Cl.uint(1), Cl.uint(7)], // equipment ID 1, 7 days
      deployer
    );
    expect(result).toBeOk(Cl.uint(350)); // 50 * 7 = 350
  });

  describe("Admin Management Tests", () => {
    it("should allow contract owner to add admins", () => {
      const { result } = simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should prevent non-owner from adding admins", () => {
      const { result } = simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user2)],
        user1 // Non-owner trying to add admin
      );
      expect(result).toBeErr(Cl.uint(100)); // err-owner-only
    });

    it("should prevent adding existing admin again", () => {
      // First add admin
      simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );

      // Try to add same admin again
      const { result } = simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );
      expect(result).toBeErr(Cl.uint(123)); // err-already-admin
    });

    it("should allow contract owner to remove admins", () => {
      // First add admin
      simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );

      // Then remove admin
      const { result } = simnet.callPublicFn(
        "Enable",
        "remove-admin",
        [Cl.principal(user1)],
        deployer
      );
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should prevent removing non-existent admin", () => {
      const { result } = simnet.callPublicFn(
        "Enable",
        "remove-admin",
        [Cl.principal(user2)], // Never added as admin
        deployer
      );
      expect(result).toBeErr(Cl.uint(124)); // err-not-admin
    });

    it("should prevent contract owner from removing themselves", () => {
      const { result } = simnet.callPublicFn(
        "Enable",
        "remove-admin",
        [Cl.principal(deployer)], // Contract owner trying to remove themselves
        deployer
      );
      expect(result).toBeErr(Cl.uint(100)); // err-owner-only
    });

    it("should correctly identify admins", () => {
      // Add admin
      simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );

      // Check if user1 is admin
      const { result: isAdmin } = simnet.callReadOnlyFn(
        "Enable",
        "is-admin",
        [Cl.principal(user1)],
        deployer
      );
      expect(isAdmin).toStrictEqual(Cl.bool(true));

      // Check if user2 is not admin
      const { result: isNotAdmin } = simnet.callReadOnlyFn(
        "Enable",
        "is-admin",
        [Cl.principal(user2)],
        deployer
      );
      expect(isNotAdmin).toStrictEqual(Cl.bool(false));
    });
  });

  describe("Emergency Pause Tests", () => {
    it("should allow contract owner to pause contract", () => {
      const { result } = simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );
      expect(result).toBeOk(Cl.bool(true));

      // Verify contract is paused
      const { result: pauseStatus } = simnet.callReadOnlyFn(
        "Enable",
        "is-contract-paused",
        [],
        deployer
      );
      expect(pauseStatus).toStrictEqual(Cl.bool(true));
    });

    it("should allow admin to pause contract", () => {
      // First add admin
      simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );

      // Admin can pause
      const { result } = simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        user1
      );
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should prevent non-admin from pausing contract", () => {
      const { result } = simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        user2 // Non-admin
      );
      expect(result).toBeErr(Cl.uint(122)); // err-admin-only
    });

    it("should only allow contract owner to unpause", () => {
      // First pause the contract
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );

      // Owner can unpause
      const { result } = simnet.callPublicFn(
        "Enable",
        "emergency-unpause",
        [],
        deployer
      );
      expect(result).toBeOk(Cl.bool(true));

      // Verify contract is unpaused
      const { result: pauseStatus } = simnet.callReadOnlyFn(
        "Enable",
        "is-contract-paused",
        [],
        deployer
      );
      expect(pauseStatus).toStrictEqual(Cl.bool(false));
    });

    it("should prevent admin from unpausing (only owner can)", () => {
      // Add admin and pause contract
      simnet.callPublicFn(
        "Enable",
        "add-admin",
        [Cl.principal(user1)],
        deployer
      );
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        user1
      );

      // Admin cannot unpause
      const { result } = simnet.callPublicFn(
        "Enable",
        "emergency-unpause",
        [],
        user1
      );
      expect(result).toBeErr(Cl.uint(100)); // err-owner-only
    });
  });

  describe("Pause State Functionality Tests", () => {
    beforeEach(() => {
      // Ensure contract is unpaused before each test
      simnet.callPublicFn(
        "Enable",
        "emergency-unpause",
        [],
        deployer
      );
    });

    it("should block service provider registration when paused", () => {
      // First pause the contract
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );

      // Try to register service provider while paused
      const { result } = simnet.callPublicFn(
        "Enable",
        "register-service-provider",
        [
          Cl.stringAscii("Test Provider"),
          Cl.stringAscii("test services")
        ],
        provider1
      );
      expect(result).toBeErr(Cl.uint(121)); // err-contract-paused
    });

    it("should block equipment registration when paused", () => {
      // Register user first
      simnet.callPublicFn(
        "Enable",
        "register-user",
        [
          Cl.principal(user1),
          Cl.stringAscii("mobility"),
          Cl.stringAscii("active"),
          Cl.uint(999999),
          Cl.uint(3),
          Cl.stringAscii("wheelchair user")
        ],
        deployer
      );

      // Pause the contract
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );

      // Try to register equipment while paused
      const { result } = simnet.callPublicFn(
        "Enable",
        "register-equipment",
        [
          Cl.stringAscii("Wheelchair"),
          Cl.stringAscii("mobility"),
          Cl.stringAscii("Standard manual wheelchair"),
          Cl.stringAscii("excellent"),
          Cl.uint(50),
          Cl.uint(200),
          Cl.stringAscii("Clean")
        ],
        user1
      );
      expect(result).toBeErr(Cl.uint(121)); // err-contract-paused
    });

    it("should block service booking when paused", () => {
      // Setup: register user and provider
      simnet.callPublicFn(
        "Enable",
        "register-user",
        [
          Cl.principal(user1),
          Cl.stringAscii("mobility"),
          Cl.stringAscii("active"),
          Cl.uint(999999),
          Cl.uint(3),
          Cl.stringAscii("wheelchair user")
        ],
        deployer
      );
      simnet.callPublicFn(
        "Enable",
        "register-service-provider",
        [
          Cl.stringAscii("Test Provider"),
          Cl.stringAscii("mobility assistance")
        ],
        provider1
      );

      // Pause the contract
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );

      // Try to create booking while paused
      const { result } = simnet.callPublicFn(
        "Enable",
        "create-service-booking",
        [
          Cl.principal(provider1),
          Cl.stringAscii("mobility assistance"),
          Cl.uint(100), // start time
          Cl.uint(60), // duration
          Cl.uint(50), // cost
          Cl.stringAscii("wheelchair accessible")
        ],
        user1
      );
      expect(result).toBeErr(Cl.uint(121)); // err-contract-paused
    });

    it("should block equipment loans when paused", () => {
      // Setup: register users and equipment
      simnet.callPublicFn(
        "Enable",
        "register-user",
        [
          Cl.principal(user1),
          Cl.stringAscii("mobility"),
          Cl.stringAscii("active"),
          Cl.uint(999999),
          Cl.uint(3),
          Cl.stringAscii("owner")
        ],
        deployer
      );
      simnet.callPublicFn(
        "Enable",
        "register-user",
        [
          Cl.principal(user2),
          Cl.stringAscii("mobility"),
          Cl.stringAscii("active"),
          Cl.uint(999999),
          Cl.uint(3),
          Cl.stringAscii("borrower")
        ],
        deployer
      );
      simnet.callPublicFn(
        "Enable",
        "register-equipment",
        [
          Cl.stringAscii("Wheelchair"),
          Cl.stringAscii("mobility"),
          Cl.stringAscii("Standard manual wheelchair"),
          Cl.stringAscii("excellent"),
          Cl.uint(50),
          Cl.uint(200),
          Cl.stringAscii("Clean")
        ],
        user1
      );

      // Pause the contract
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );

      // Try to create equipment loan while paused
      const { result } = simnet.callPublicFn(
        "Enable",
        "create-equipment-loan",
        [
          Cl.uint(1), // equipment ID
          Cl.uint(100), // start date
          Cl.uint(107) // end date (7 days)
        ],
        user2
      );
      expect(result).toBeErr(Cl.uint(121)); // err-contract-paused
    });

    it("should allow operations after unpausing", () => {
      // Pause and then unpause
      simnet.callPublicFn(
        "Enable",
        "emergency-pause",
        [],
        deployer
      );
      simnet.callPublicFn(
        "Enable",
        "emergency-unpause",
        [],
        deployer
      );

      // Should now work normally
      const { result } = simnet.callPublicFn(
        "Enable",
        "register-service-provider",
        [
          Cl.stringAscii("Test Provider"),
          Cl.stringAscii("test services")
        ],
        provider1
      );
      expect(result).toBeOk(Cl.bool(true));
    });
  });
});
