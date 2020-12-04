pragma solidity >= 0.6.2;

import 'interfaces/TwicyInterface.sol';
import 'modifiers/TransferValueModifier.sol';
import 'utils/ArrayUtil.sol';

/**
 * Error codes
 *     • 100 — Method only for root
 *     • 200 — Invalid transfer value
 */
contract TwicyStorage is ArrayUtil,
                         TransferValueModifier {
    /*************
     * CONSTANTS *
     *************/
    uint128 private constant MINIMUM_BALANCE         = 1e9;   // 1💎
    uint128 private constant MINIMUM_TRANSFER_VALUE  = 0.1e9; // 0.1💎
    uint8   private constant MAX_DEPOSITS_FOR_PAYOUT = 128;   // Maximum number of deposits per method call



    /**************
     * STRUCTURES *
     **************/
    struct Deposit {
        address owner;
        uint128 reward;
    }



    /*************
     * VARIABLES *
     *************/
    address   private _rootAddress;
    Deposit[] private _deposits;
    uint128   private _amountAvailableForPayout;
    uint32    private _payoutsCount;



    /*************
     * MODIFIERS *
     *************/
    modifier accept {
        tvm.accept();
        _;
    }

    modifier onlyRoot {
        require(msg.sender == _rootAddress, 100, "Method only for root");
        _;
    }



    /***************
     * CONSTRUCTOR *
     ***************/
    constructor(
        address rootAddress
    ) public accept {
        _rootAddress = rootAddress;
    }



    /*********
     * VIEWS *
     *********/
    function getRootAddress() public view returns (address rootAddress) { return _rootAddress; }
    function getDepositsCount() public view returns (uint256 depositsCount) { return _deposits.length; }
    function getAmountAvailableForPayout() public view returns (uint128 amountAvailableForPayout) { return _amountAvailableForPayout; }
    function getPayoutsCount() public view returns (uint32 payoutsCount) { return _payoutsCount; }

    function getDeposits(uint64 offset, uint64 limit) public view returns (
        address[] owners,
        uint128[] rewards,
        uint256   totalLength
    ) {
        Deposit[] deposits = _deposits;
        uint64 endIndex = _getEndIndex(offset, limit, deposits.length);
        for (uint64 i = offset; i < endIndex; i++) {
            Deposit deposit = deposits[i];
            owners.push(deposit.owner);
            rewards.push(deposit.reward);
        }
        return (owners, rewards, deposits.length);
    }



    /************
     * EXTERNAL *
     ************/
    function dispatchReferrerAddress(address sender, uint128 value, uint32 index) external onlyRoot accept {
        address referrer = _deposits[index].owner;
        TwicyInterface(_rootAddress).onReceiveReferrerAddress{value: _getTransferValue()}(sender, referrer, value);
    }

    function save(address sender, uint128 reward) external onlyRoot accept {
        Deposit deposit = Deposit(sender, reward);
        _deposits.push(deposit);
    }

    function dispatchDepositsForPayout(uint128 value) external onlyRoot accept {
        address[] owners;
        uint128[] rewards;

        Deposit[] deposits = _deposits;
        uint128 amountAvailableForPayout = _amountAvailableForPayout + value;
        uint32 payoutsCount = _payoutsCount;

        uint64 endIndex = _getEndIndex(payoutsCount, MAX_DEPOSITS_FOR_PAYOUT, deposits.length);
        for (uint64 i = payoutsCount; i < endIndex; i++) {
            Deposit deposit = _deposits[i];
            if (amountAvailableForPayout >= deposit.reward) {
                amountAvailableForPayout -= deposit.reward;
                owners.push(deposit.owner);
                rewards.push(deposit.reward);
                payoutsCount++;
            } else
                break;
        }

        if (owners.length > 0)
            TwicyInterface(_rootAddress).onReceiveDepositsForPayout{value: _getTransferValue()}(owners, rewards);
        _amountAvailableForPayout = amountAvailableForPayout;
        _payoutsCount = payoutsCount;
    }

    function sendTransaction(address destination, uint128 value) external onlyRoot accept validTransferValue(value) {
        destination.transfer(value);
    }



    /***********
     * PRIVATE *
     ***********/
    function _getTransferValue() private returns (uint128) {
        uint128 balance = address(this).balance;
        return balance > (MINIMUM_BALANCE + MINIMUM_TRANSFER_VALUE) ?
            balance - MINIMUM_BALANCE :
            MINIMUM_TRANSFER_VALUE;
    }
}