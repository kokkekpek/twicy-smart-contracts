pragma solidity >= 0.6.2;

contract HexadecimalNumberUtil {
    /*************
     * CONSTANTS *
     *************/
    uint8 private constant FIRST_INDEX        = 2;
    uint8 private constant MIN_MESSAGE_LENGTH = 3;  // "0x1" - example of one of the shortest numbers
    uint8 private constant MAX_MESSAGE_LENGTH = 16; // "0x1234567890abcdef" - example of one of the longest numbers

    uint8 private constant UTF8_x = 0x78;

    uint8 private constant UTF8_0 = 0x30;
    uint8 private constant UTF8_1 = 0x31;
    uint8 private constant UTF8_2 = 0x32;
    uint8 private constant UTF8_3 = 0x33;
    uint8 private constant UTF8_4 = 0x34;
    uint8 private constant UTF8_5 = 0x35;
    uint8 private constant UTF8_6 = 0x36;
    uint8 private constant UTF8_7 = 0x37;
    uint8 private constant UTF8_8 = 0x38;
    uint8 private constant UTF8_9 = 0x39;

    uint8 private constant UTF8_A = 0x41;
    uint8 private constant UTF8_B = 0x42;
    uint8 private constant UTF8_C = 0x43;
    uint8 private constant UTF8_D = 0x44;
    uint8 private constant UTF8_E = 0x45;
    uint8 private constant UTF8_F = 0x46;

    uint8 private constant UTF8_a = 0x61;
    uint8 private constant UTF8_b = 0x62;
    uint8 private constant UTF8_c = 0x63;
    uint8 private constant UTF8_d = 0x64;
    uint8 private constant UTF8_e = 0x65;
    uint8 private constant UTF8_f = 0x66;



    /********
     * PURE *
     ********/
    /**
     * Returns true if the message is a hexadecimal number.
     * Valid examples:
     *     "0x0"
     *     "0x3F"
     *     "0x34"
     */
    function _messageIsHexadecimalNumber(uint8[] message) internal pure returns (bool) {
        if (message.length < MIN_MESSAGE_LENGTH) return false;
        if (message.length > MAX_MESSAGE_LENGTH) return false;
        if (message[0] != UTF8_0) return false;
        if (message[1] != UTF8_x) return false;

        for (uint64 i = FIRST_INDEX; i < message.length; i++) {
            uint8 character = message[i];
            if (
                character != UTF8_0 &&
                character != UTF8_1 &&
                character != UTF8_2 &&
                character != UTF8_3 &&
                character != UTF8_4 &&
                character != UTF8_5 &&
                character != UTF8_6 &&
                character != UTF8_7 &&
                character != UTF8_8 &&
                character != UTF8_9 &&

                character != UTF8_A &&
                character != UTF8_B &&
                character != UTF8_C &&
                character != UTF8_D &&
                character != UTF8_E &&
                character != UTF8_F &&

                character != UTF8_a &&
                character != UTF8_b &&
                character != UTF8_c &&
                character != UTF8_d &&
                character != UTF8_e &&
                character != UTF8_f
            ) return false;
        }
        return true;
    }

    /**
     * Read hexadecimal number from message.
     * Examples:
     *     "0x0"  // 0
     *     "0x3F" // 63
     *     "0x34" // 52
     */
    function _readHexadecimalNumberFromMessage(uint8[] message) internal pure returns (uint64) {
        uint64 result;
        for (uint64 i = FIRST_INDEX; i < message.length; i++) {
            uint8 character = message[i];
            result = result << 4;
            if (character == UTF8_1) result += 0x1;
            if (character == UTF8_2) result += 0x2;
            if (character == UTF8_3) result += 0x3;
            if (character == UTF8_4) result += 0x4;
            if (character == UTF8_5) result += 0x5;
            if (character == UTF8_6) result += 0x6;
            if (character == UTF8_7) result += 0x7;
            if (character == UTF8_8) result += 0x8;
            if (character == UTF8_9) result += 0x9;

            if (character == UTF8_A) result += 0xA;
            if (character == UTF8_B) result += 0xB;
            if (character == UTF8_C) result += 0xC;
            if (character == UTF8_D) result += 0xD;
            if (character == UTF8_E) result += 0xE;
            if (character == UTF8_F) result += 0xF;

            if (character == UTF8_a) result += 0xA;
            if (character == UTF8_b) result += 0xB;
            if (character == UTF8_c) result += 0xC;
            if (character == UTF8_d) result += 0xD;
            if (character == UTF8_e) result += 0xE;
            if (character == UTF8_f) result += 0xF;
        }
        return result;
    }

    /**
     * Returns UTF-8 encoded characters.
     * Examples:
     *     _getMessageWithHexadecimalNumber(0);      // "0x0"
     *     _getMessageWithHexadecimalNumber(10);     // "0xA"
     *     _getMessageWithHexadecimalNumber(100);    // "0x64"
     *     _getMessageWithHexadecimalNumber(123456); // "0x1E240"
     */
    function _getMessageWithHexadecimalNumber(uint64 number) internal pure returns (uint8[]) {
        uint8[] result = [UTF8_0, UTF8_x];

        uint8[] characters;
        for (uint8 i = 0; i < MAX_MESSAGE_LENGTH; i++) {
            uint8 characterCode = uint8(number % 0x10);

            if (characterCode == 0x0) characters.push(UTF8_0);
            if (characterCode == 0x1) characters.push(UTF8_1);
            if (characterCode == 0x2) characters.push(UTF8_2);
            if (characterCode == 0x3) characters.push(UTF8_3);
            if (characterCode == 0x4) characters.push(UTF8_4);
            if (characterCode == 0x5) characters.push(UTF8_5);
            if (characterCode == 0x6) characters.push(UTF8_6);
            if (characterCode == 0x7) characters.push(UTF8_7);
            if (characterCode == 0x8) characters.push(UTF8_8);
            if (characterCode == 0x9) characters.push(UTF8_9);

            if (characterCode == 0xA) characters.push(UTF8_A);
            if (characterCode == 0xB) characters.push(UTF8_B);
            if (characterCode == 0xC) characters.push(UTF8_C);
            if (characterCode == 0xD) characters.push(UTF8_D);
            if (characterCode == 0xE) characters.push(UTF8_E);
            if (characterCode == 0xF) characters.push(UTF8_F);

            number = number >> 4;
            if (number == 0)
                break;
        }

        for (int256 i = int256(characters.length - 1); i >= 0; i--)
            result.push(characters[uint256(i)]);

        return result;
    }
}