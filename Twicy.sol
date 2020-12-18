pragma solidity >= 0.6.2;

import 'TwicyStorage.sol';
import 'interfaces/TwicyInterface.sol';
import 'modifiers/MigrationModifier.sol';
import 'modifiers/TransferValueModifier.sol';
import 'utils/ArrayUtil.sol';
import 'utils/HexadecimalNumberUtil.sol';
import 'utils/MessageUtil.sol';
import 'utils/PseudoRandomUtil.sol';
import 'utils/TextUtil.sol';
import 'utils/TwicyRewardUtil.sol';

/**
 * ████████╗██╗    ██╗██╗ ██████╗██╗   ██╗
 * ╚══██╔══╝██║    ██║██║██╔════╝╚██╗ ██╔╝
 *    ██║   ██║ █╗ ██║██║██║      ╚████╔╝
 *    ██║   ██║███╗██║██║██║       ╚██╔╝
 *    ██║   ╚███╔███╔╝██║╚██████╗   ██║
 *    ╚═╝    ╚══╝╚══╝ ╚═╝ ╚═════╝   ╚═╝
 * First risk-game on Free TON
 *
 * Error codes
 *     • 100 — Method only for the owner
 *     • 101 — Method only for storage
 *     • 102 — A deposit is less than the minimum value
 *     • 103 — A deposit is more than the maximum value
 *     • 104 — More storages are required
 *     • 105 — Invalid referral id
 *     • 106 — Invalid storage address
 *     • 200 — Invalid transfer value
 *     • 300 — Method can only be called before migration
 *     • 301 — Method can only be called after migration
 */
contract Twicy is TwicyInterface,
                  MigrationModifier,
                  TransferValueModifier,
                  ArrayUtil,
                  HexadecimalNumberUtil,
                  MessageUtil,
                  PseudoRandomUtil,
                  TextUtil,
                  TwicyRewardUtil {
    /*************
     * CONSTANTS *
     *************/
    uint8   private constant DEFAULT_DEPLOYED_STORAGES = 2;
    uint128 private constant STORAGE_DEPLOY_VALUE      = 1e9;     // 1💎
    uint128 private constant STORAGE_TRANSFER_VALUE    = 0.2e9;   // 0.2💎
    uint128 private constant CONFIRMATION_VALUE        = 0.001e9; // 0.001💎
    uint128 private constant MIN_DEPOSIT               = 5e9;     // 5💎
    uint128 private constant MAX_DEPOSIT               = 50e9;    // 50💎



    /*************
     * VARIABLES *
     *************/
    TvmCell   private _storageCode;
    uint32    private _storageLength;
    address[] private _storageAddresses;
    uint128[] private _storageAmounts;
    uint32    private _storageIdForPayout;
    uint64    private _depositsCount;
    uint256   private _total;

    mapping(address => bool) _storages;



    /*************
     * MODIFIERS *
     *************/
    modifier accept {
        tvm.accept();
        _;
    }

    modifier onlyOwner {
        require(msg.pubkey() == tvm.pubkey(), 100, "Method only for owner");
        _;
    }

    modifier onlyStorage() {
        require(_storages.exists(msg.sender), 101, "Method only for storage");
        _;
    }

    modifier validDeposit() {
        require(msg.value >= MIN_DEPOSIT, 102, "A deposit is less than the minimum value");
        require(msg.value <= MAX_DEPOSIT, 103, "A deposit is more than the maximum value");
        _;
    }

    modifier enoughStorages() {
        require(getDepositsLimit() >= _depositsCount, 104, "More storages are required");
        _;
    }

    modifier validReferralId(uint64 referrerId) {
        require(referrerId < _depositsCount, 105, "Invalid referral id");
        _;
    }

    modifier validStorage(address storageAddress) {
        require(_storages.exists(storageAddress), 106, "Invalid storage address");
        _;
    }



    /***************
     * CONSTRUCTOR *
     ***************/
    constructor(TvmCell storageCode,uint32  storageLength) public accept {
        _storageCode = storageCode;
        _storageLength = storageLength;
        _saveText();
        deployStorage(DEFAULT_DEPLOYED_STORAGES);
    }



    /***********
     * GETTERS *
     ***********/
    function getStorageLength() public view returns (uint32 storageLength) { return _storageLength; }
    function getStorageIdForPayout() public view returns (uint32 storageIdForPayout) { return _storageIdForPayout; }
    function getDepositsCount() public view returns (uint64 depositsCount) { return _depositsCount; }
    function getTotal() public view returns (uint256 total) { return _total; }

    function getDepositsLimit() public view returns (uint64 depositLimit) {
        return uint64(_storageLength * _storageAddresses.length);
    }

    function getStorages(uint32 offset, uint32 limit) public view returns (
        address[] addresses,
        uint128[] amounts,
        uint256   totalLength
    ) {
        address[] storageAddresses = _storageAddresses;
        uint128[] storageAmounts = _storageAmounts;
        uint64 endIndex = _getEndIndex(offset, limit, storageAddresses.length);
        for (uint64 i = offset; i < endIndex; i++) {
            addresses.push(storageAddresses[i]);
            amounts.push(storageAmounts[i]);
        }
        return (addresses, amounts, storageAddresses.length);
    }



    /***********************
     * PUBLIC * ONLY OWNER *
     ***********************/
    function deployStorage(uint8 count) public onlyOwner accept returns (address[] addresses) {
        address[] storageAddresses = _storageAddresses;
        uint128[] storageAmounts = _storageAmounts;
        mapping(address => bool) storages = _storages;
        address rootAddress = address(this);

        for (uint8 i = 0; i < count; i++) {
            uint256 random = _getRandom(i);
            TvmCell storageData = tvm.buildEmptyData(random);
            TvmCell stateInit = tvm.buildStateInit(_storageCode, storageData);
            address storageAddress = new TwicyStorage{stateInit: stateInit, value: STORAGE_DEPLOY_VALUE}(rootAddress);

            storageAddresses.push(storageAddress);
            storageAmounts.push(0);
            storages[storageAddress] = true;
            addresses.push(storageAddress);
        }

        _storageAddresses = storageAddresses;
        _storageAmounts = storageAmounts;
        _storages = storages;
        return addresses;
    }

    function sendTransaction(
        address destination,
        uint128 value
    ) public view onlyOwner accept validTransferValue(value) {
        destination.transfer(value);
    }

    function storageSendTransaction(
        address storageAddress,
        address destination,
        uint128 value
    ) public view onlyOwner accept validStorage(storageAddress) {
        TwicyStorage(storageAddress).sendTransaction(destination, value);
    }



    /***********************************
     * PUBLIC * ONLY OWNER * MIGRATION *
     ***********************************/
    function migrate(
        uint128[] storageAmounts,
        uint32    storageIdForPayout,
        uint64    depositsCount,
        uint256   total
    ) public onlyOwner accept beforeMigration {
        _storageAmounts = storageAmounts;
        _storageIdForPayout = storageIdForPayout;
        _depositsCount = depositsCount;
        _total = total;
    }

    function migrateStorage(
        address storageAddress,
        uint128 amountAvailableForPayout,
        uint32  payoutsCount
    ) public onlyOwner accept beforeMigration {
        TwicyStorage(storageAddress).migrate{value: 1e9}(amountAvailableForPayout, payoutsCount);
    }

    function migrateStorageDeposits(
        address   storageAddress,
        address[] senders,
        uint128[] rewards
    ) public onlyOwner accept beforeMigration {
        TwicyStorage(storageAddress).migrateDeposits{value: 1e9}(senders, rewards);
    }

    function completeMigration() public onlyOwner beforeMigration accept {
        _migrationCompleted = true;
    }



    /********************
     * PUBLIC * DEPOSIT *
     ********************/
    function depositWithReferralId(uint64 referralId) public validDeposit enoughStorages afterMigration {
        address sender = msg.sender;
        uint128 value = uint128(msg.value);
        _dispatchReferrerAddress(sender, value, referralId);
    }

    function deposit() public validDeposit enoughStorages afterMigration {
        address sender = msg.sender;
        uint128 value = uint128(msg.value);
        _depositWithoutReferralBonus(sender, value);
    }



    /************
     * EXTERNAL *
     ************/
    function onReceiveReferrerAddress(address sender, address referrer, uint128 value) external override onlyStorage {
        if (sender == referrer)
            _depositWithoutReferralBonus(sender, value);
        else {
            uint128 referrerPayout = _getReferrerPayout(value);
            referrer.transfer({value: referrerPayout, body: _getTransferBody(TEXT_REFERRAL)});
            _depositWithReferralBonus(sender, value);
        }
    }

    function onReceiveDepositsForPayout(address[] owners, uint128[] rewards) external override onlyStorage {
        for (uint64 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            uint128 reward = rewards[i];
            owner.transfer({value: reward, body: _getTransferBody(TEXT_REWARD)});
        }
    }



    /***********
     * RECEIVE *
     ***********/
    receive() external validDeposit enoughStorages afterMigration {
        address sender = msg.sender;
        uint128 value = uint128(msg.value);
        uint8[] message = _readMessage(msg.data);

        ///////////////////////////////////////
        // 1. "bank" comment                 //
        //    Just increase contract balance //
        ///////////////////////////////////////
        if (_messageIsEqual(message, TEXT_BANK))
            _receiveBank(sender);

        ////////////////////////////////////////
        // 2. Deposit id in comment           //
        //    Examples: "0x0", "0x3F", "0x34" //
        ////////////////////////////////////////
        else if (_messageIsHexadecimalNumber(message))
            _receiveDepositWithReferralId(sender, value, message);

        //////////////////////////
        // 3. Any other comment //
        //////////////////////////
        else
            _receiveDeposit(sender, value);
    }

    function _receiveBank(address sender) private view {
        sender.transfer({value: CONFIRMATION_VALUE, body: _getTransferBody(TEXT_OK)});
    }

    function _receiveDepositWithReferralId(address sender, uint128 value, uint8[] message) private {
        uint64 referralId = _readHexadecimalNumberFromMessage(message);
        _dispatchReferrerAddress(sender, value, referralId);
    }

    function _receiveDeposit(address sender, uint128 value) private {
        _depositWithoutReferralBonus(sender, value);
    }



    /***********
     * PRIVATE *
     ***********/
    function _dispatchReferrerAddress(address sender, uint128 value, uint64 referralId) private validReferralId(referralId) {
        uint32 storageId = _getStorageId(referralId);
        address storageAddress = _storageAddresses[storageId];
        uint32 index = uint32(referralId % _storageLength);
        TwicyStorage(storageAddress).dispatchReferrerAddress{value: STORAGE_TRANSFER_VALUE}(sender, value, index);
    }

    function _getStorageId(uint64 depositId) private view returns(uint32) {
        return uint32(depositId / _storageLength);
    }

    function _depositWithReferralBonus(address sender, uint128 value) private {
        uint128 reward = _getBonusReward(value);
        uint128 payout = _getBonusUsersPayout(value);
        _deposit(sender, value, reward, payout);
    }

    function _depositWithoutReferralBonus(address sender, uint128 value) private {
        uint128 reward = _getRegularReward(value);
        uint128 payout = _getRegularUsersPayout(value);
        _deposit(sender, value, reward, payout);
    }

    function _deposit(address sender, uint128 value, uint128 reward, uint128 payoutValue) private {
        _depositConfirmation(sender);
        _save(sender, value, reward);
        _dispatchDepositsForPayout(payoutValue);
    }

    function _depositConfirmation(address sender) private view {
        uint8[] message = _getMessageWithHexadecimalNumber(_depositsCount);
        sender.transfer({value: CONFIRMATION_VALUE, body: _getTransferBody(message)});
    }

    function _save(address sender, uint128 value, uint128 reward) private {
        uint32 storageId = _getStorageId(_depositsCount);
        address storageAddress = _storageAddresses[storageId];
        TwicyStorage(storageAddress).save{value: STORAGE_TRANSFER_VALUE}(sender, reward);

        _storageAmounts[storageId] += reward;
        _total += value;
        _depositsCount++;
    }

    function _dispatchDepositsForPayout(uint128 payoutValue) private {
        address[] storageAddresses = _storageAddresses;
        uint128[] storageAmounts = _storageAmounts;
        uint32 storageIdForPayout = _storageIdForPayout;

        for (uint64 i = storageIdForPayout; i < storageAddresses.length; i++) {
            address storageAddress = storageAddresses[i];
            uint128 storageAmount = storageAmounts[i];
            if (payoutValue >= storageAmount) {
                payoutValue -= storageAmount;
                storageAmounts[i] = 0;
                TwicyStorage(storageAddress).dispatchDepositsForPayout{value: STORAGE_TRANSFER_VALUE}(storageAmount);
                storageIdForPayout++;
            } else {
                storageAmounts[i] -= payoutValue;
                TwicyStorage(storageAddress).dispatchDepositsForPayout{value: STORAGE_TRANSFER_VALUE}(payoutValue);
                break;
            }
        }

        _storageAmounts = storageAmounts;
        _storageIdForPayout = storageIdForPayout;
    }
}