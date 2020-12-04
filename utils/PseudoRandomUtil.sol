pragma solidity >= 0.6.2;

contract PseudoRandomUtil {
    /********************
     * RANDOM INTRINSIC *
     ********************/
    function tvm_rand_seed() private pure returns (uint256) {}



    /********
     * PURE *
     ********/
    function _getRandom(uint256 salt) internal pure returns (uint256) {
        TvmBuilder builder;
        builder.store(tvm_rand_seed(), now, salt);
        return tvm.hash(builder.toCell());
    }
}