pragma solidity >= 0.6.2;

contract TwicyRewardUtil {
    /*************
     * CONSTANTS *
     *************/
    uint16 private constant REGULAR_REWARD_MULTIPLY  = 2e3;    // ×2
    uint16 private constant BONUS_REWARD_MULTIPLY    = 2.2e3;  // ×2.2
    uint16 private constant REGULAR_USERS_PART       = 0.90e3; // 90%
    uint16 private constant BONUS_USERS_PART         = 0.85e3; // 85%
    uint16 private constant REFERRER_PART            = 0.05e3; // 5%
    uint16 private constant MULTIPLY_DIVIDER         = 1e3;


    /********
     * PURE *
     ********/
    function _getRegularReward(uint128 value) internal pure returns (uint128) {
        return math.muldiv(value, REGULAR_REWARD_MULTIPLY, MULTIPLY_DIVIDER);
    }

    function _getBonusReward(uint128 value) internal pure returns (uint128) {
        return math.muldiv(value, BONUS_REWARD_MULTIPLY, MULTIPLY_DIVIDER);
    }

    function _getRegularUsersPayout(uint128 value) internal pure returns (uint128) {
        return math.muldiv(value, REGULAR_USERS_PART, MULTIPLY_DIVIDER);
    }

    function _getBonusUsersPayout(uint128 value) internal pure returns (uint128) {
        return math.muldiv(value, BONUS_USERS_PART, MULTIPLY_DIVIDER);
    }

    function _getReferrerPayout(uint128 value) internal pure returns (uint128) {
        return math.muldiv(value, REFERRER_PART, MULTIPLY_DIVIDER);
    }
}