pragma solidity >= 0.6.2;

interface TwicyInterface {
    function onReceiveReferrerAddress(address sender, address referrer, uint128 value) external;
    function onReceiveDepositsForPayout(address[] owners, uint128[] rewards) external;
}