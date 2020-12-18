pragma solidity >= 0.6.2;

/**
 * Migration from v1.0 to v1.1
 *
 * Error codes
 *     • 300 — Method can only be called before migration
 *     • 301 — Method can only be called after migration
 */
contract MigrationModifier {
    /*************
     * VARIABLES *
     *************/
    bool internal _migrationCompleted;



    /*************
     * MODIFIERS *
     *************/
    modifier beforeMigration() {
        require(!_migrationCompleted, 300, "Method can only be called before migration");
        _;
    }

    modifier afterMigration() {
        require(_migrationCompleted, 301, "Method can only be called after migration");
        _;
    }
}