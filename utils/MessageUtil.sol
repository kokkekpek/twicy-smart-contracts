pragma solidity >= 0.6.2;

contract MessageUtil {
    /*************
     * CONSTANTS *
     *************/
    uint16 private constant MESSAGE_PREFIX_BITS = 0x20; // 32-bit prefix that contains zeros
    uint16 private constant UTF8_CHARACTER_BITS = 0x8;  // 8-bit UTF-8 encoded character



    /********
     * PURE *
     ********/
    /**
     * Read msg.data. Returns an array of UTF-8 encoded characters.
     */
    function _readMessage(TvmSlice payload) internal pure returns (uint8[]) {
        uint8[] result;
        if (!_isMessageContainer(payload)) return result;
        TvmSlice message = payload.loadRefAsSlice();
        if (!_isMessage(message)) return result;

        uint16 bits = message.bits();
        uint256 length = bits / UTF8_CHARACTER_BITS;
        for (uint64 i = 0; i < length; i++)
            result.push(message.loadUnsigned(UTF8_CHARACTER_BITS));
        return result;
    }

    /**
     * Returns true if the slice contains a message.
     */
    function _isMessageContainer(TvmSlice slice) private pure returns (bool) {
        uint16 bits = slice.bits();
        uint8 refs = slice.refs();
        uint64 depth = slice.depth();
        return bits == MESSAGE_PREFIX_BITS && refs == 1 && depth == 1;
    }

    /**
     * Returns true if the slice contains UTF-8 encoded characters.
     */
    function _isMessage(TvmSlice slice) private pure returns (bool) {
        uint16 bits = slice.bits();
        uint8 refs = slice.refs();
        uint64 depth = slice.depth();
        return (bits % UTF8_CHARACTER_BITS) == 0 && refs == 0 && depth == 0;
    }

    /**
     * Returns true if the message and text are the same.
     */
    function _messageIsEqual(uint8[] message, uint8[] text) internal pure returns (bool) {
        if (message.length != text.length) return false;
        for (uint64 i = 0; i < text.length; i++)
            if (message[i] != text[i]) return false;
        return true;
    }

    /**
     * Returns TvmCell with message.
     */
    function _getTransferBody(uint8[] message) internal pure returns (TvmCell) {
        TvmBuilder builderString;
        for (uint64 i = 0; i < message.length; i++)
            builderString.storeUnsigned(message[i], UTF8_CHARACTER_BITS);
        TvmBuilder builder;
        builder.storeUnsigned(0, MESSAGE_PREFIX_BITS);
        builder.storeRef(builderString);
        return builder.toCell();
    }
}