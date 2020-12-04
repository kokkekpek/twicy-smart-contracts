pragma solidity >= 0.6.2;

contract ArrayUtil {
    /********
     * PURE *
     ********/
    /**
     * Examples:
     *     _getEndIndexes(0,  10, 20); // Return 10
     *     _getEndIndexes(0,  30, 20); // Return 20
     *     _getEndIndexes(5,  10, 20); // Return 15
     *     _getEndIndexes(5,  30, 20); // Return 20
     *     _getEndIndexes(10, 10, 20); // Return 20
     *     _getEndIndexes(10, 30, 20); // Return 20
     */
    function _getEndIndex(uint64 offset, uint64 limit, uint256 arrayLength) internal pure returns (uint64) {
        uint64 endIndex = offset + limit;
        return (endIndex > arrayLength) ? uint64(arrayLength) : endIndex;
    }
}