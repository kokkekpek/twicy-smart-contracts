pragma solidity >= 0.6.2;

contract TextUtil {
    /************
     * MESSAGES *
     ************/
    uint8[] internal TEXT_BANK;
    uint8[] internal TEXT_OK;
    uint8[] internal TEXT_REFERRAL;
    uint8[] internal TEXT_REWARD;

    function _saveText() internal {
        TEXT_BANK     = [0x62, 0x61, 0x6E, 0x6B];                         // "bank"
        TEXT_OK       = [0x4F, 0x4B];                                     // "OK"
        TEXT_REFERRAL = [0x52, 0x45, 0x46, 0x45, 0x52, 0x52, 0x41, 0x4C]; // "REFERRAL"
        TEXT_REWARD   = [0x52, 0x45, 0x57, 0x41, 0x52, 0x44];             // "REWARD"
    }
}