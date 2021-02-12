// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {
    ISuperfluid,
    ISuperToken,
    ISuperAgreement,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {
    SuperAppBase
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";


import "@openzeppelin/contracts/access/Ownable.sol";
import { Int96SafeMath } from "./utils/Int96SafeMath.sol";


contract Creator is SuperAppBase {
    using Int96SafeMath for int96;
    // -----------------------------------------
    // Errors
    // -----------------------------------------

    string private constant _ERR_STR_LOW_FLOW_RATE = "Superfluid: flow rate not enough";

    // -----------------------------------------
    // Storage
    // -----------------------------------------

    enum Status { unSubscribed, pendingSubscribe, pendingUnsubscribe, subscribed }
    enum Approval { neutral, like, dislike }

    struct Subscriber {
        string sigKey;
        string pubKey;
        string textileKey;
        Status status;
    }

    struct Post {
        string metadataURL;
        uint totalLikes;
        uint totalDislikes;
        address[] votees;
    }

    address[] emptyVoteArrray;

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token

    address public CreatonAdmin;
    address public creator;
    address public treasury;
    int96 public treasury_fee;

    string public description;
    int96 public subscriptionPrice;
    int96 private _MINIMUM_FLOW_RATE = subscriptionPrice.mul(1e18).div(3600 * 24 * 30);
    mapping (address => Subscriber) public subscribers;
    address[] public subscribersList;
    Post[] public posts;
    uint postCounter = 0;
    bool streaming; // shows if streams are open to creator and treasury

    // -----------------------------------------
    // Constructor
    // -----------------------------------------

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken
    ) {

        CreatonAdmin = msg.sender;

        assert(address(host) != address(0));
        assert(address(cfa) != address(0));
        assert(address(acceptedToken) != address(0));

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL;
        _host.registerApp(configWord);

    }

    function init(
        address owner,
        string calldata _description,
        uint256 _subscriptionPrice,
        address _treasury,
        int96 _treasury_fee
    ) public {
        creator = owner;
        description = _description;
        subscriptionPrice = int96(_subscriptionPrice);
        treasury = _treasury;
        treasury_fee = _treasury_fee;
        streaming = false;
    }

    // -----------------------------------------
    // Logic
    // -----------------------------------------

    receive() external payable {}

    function withdrawEth() public {
        (bool success, ) = msg.sender.call{value: (address(this).balance)}("Not admin");
        require(success, "No balance");
    }

    // function recoverTokens(address _token) external isCreator {
    //     ERC20(_token).approve(address(this), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    //     ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
    // }

    function acceptSubscribe(address _address) external  {
       require(subscribers[_address].status == Status.pendingSubscribe, "Not pending subscribe");
       subscribers[_address].status = Status.subscribed;
    }

    function acceptUnsubscribe(address _address) external  {
       require(subscribers[_address].status == Status.pendingUnsubscribe, "Not pending unsubscribe");
       delete subscribers[_address];
    }

    function bulkAcceptSubscribe(address[] memory _addresses) external  {
        for(uint i = 0; i < _addresses.length; i++) {
            subscribers[_addresses[i]].status = Status.subscribed;
        }
    }

    function bulkAcceptUnsubscribe(address[] memory _addresses) external  {
        for(uint i = 0; i < _addresses.length; i++) {
            delete subscribers[_addresses[i]];
        }
    }

    function upload(string memory _metadataURL) external {
       posts.push(Post(_metadataURL, 0, 0, emptyVoteArrray));
    }

    function getPostCount() public view returns (uint) {
        return posts.length;
    }

    function getSubscriberCount() public view returns (uint) {
        return subscribersList.length;
    }

    function hasLiked(address _address, uint _index) public view returns(bool) {
        for(uint i = 0; i < posts[_index].votees.length; i++) {
            if(posts[_index].votees[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function like(address _address, uint _index, uint approvalEnum) external {
        require(subscribers[_address].status == Status.subscribed, "Not subscribed");
        require(approvalEnum == 1 || approvalEnum == 2, "Invalid approval enum");
        require(hasLiked(_address, _index) == false, 'Already liked');

        if(approvalEnum == 1) {
            posts[_index].totalLikes++;
            posts[_index].votees.push(_address);
        } else {
            posts[_index].totalDislikes++;
            posts[_index].votees.push(_address);

        }
    }

    // -----------------------------------------
    // utility
    // -----------------------------------------

    function percentage (
        int96 num,
        int96 percent
    ) public pure returns (int96) {
        return num.mul(percent).div(100);
    }

    // -----------------------------------------
    // Superfluid Logic
    // -----------------------------------------

    function _addSubscriber(address _address, string memory _sigKey, string memory _pubKey, string memory _textileKey) private {
        subscribersList.push(_address);
        subscribers[_address] = Subscriber(_sigKey, _pubKey, _textileKey, Status.pendingSubscribe);
    }

    function _delSubscriber(address _address) private {
        if(subscribers[_address].status == Status.subscribed){
            subscribers[_address].status = Status.pendingUnsubscribe;
        }
        if(subscribers[_address].status == Status.pendingSubscribe){
            delete subscribers[_address];
        }
    }

    function _subscribe (
        bytes calldata ctx,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata cbdata
    ) private returns (bytes memory newCtx){

        (, int96 flowRate, , ) = IConstantFlowAgreementV1(agreementClass).getFlowByID(_acceptedToken, agreementId);
        require(flowRate >= _MINIMUM_FLOW_RATE, _ERR_STR_LOW_FLOW_RATE);

        ISuperfluid.Context memory context = _host.decodeCtx(ctx); // should give userData
        address sender = context.msgSender; // subscriber
        (string memory sigKey, string memory pubKey, string memory textileKey) = abi.decode(context.userData, (string, string, string)); // this is reallyy tricky
        _addSubscriber(sender, sigKey, pubKey, textileKey);

        return _updateCreatorFlows(ctx);
    }

    function _updateSubscribe(
        bytes calldata ctx,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata cbdata
    ) private returns (bytes memory newCtx){

        (, int96 flowRate, , ) = IConstantFlowAgreementV1(agreementClass).getFlowByID(_acceptedToken, agreementId);
        require(flowRate >= _MINIMUM_FLOW_RATE, _ERR_STR_LOW_FLOW_RATE);

        return _updateCreatorFlows(ctx);
    }

    function _unsubscribe (
        bytes calldata ctx
    ) private returns (bytes memory newCtx){
        address sender = _host.decodeCtx(ctx).msgSender;
        _delSubscriber(sender);

        return _updateCreatorFlows(ctx);
    }

    function _updateCreatorFlows(
        bytes calldata ctx
    ) private returns (bytes memory newCtx){

        int96 contractFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
        int96 contract2creator = percentage(contractFlowRate, treasury_fee);
        int96 contract2treasury = contractFlowRate.sub(contract2creator);

        if (streaming){
            if (contractFlowRate > 0){ // is there any flow coming in? function (number of pending and subscribed peeps)

                // update flow to creator
                (newCtx, ) = _host.callAgreementWithContext(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.updateFlow.selector,
                        _acceptedToken,
                        creator,
                        contract2creator,
                        new bytes(0)
                    ),
                    new bytes(0),
                    ctx
                );

                // update flow to treasury
                (newCtx, ) = _host.callAgreementWithContext(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.updateFlow.selector,
                        _acceptedToken,
                        treasury,
                        contract2treasury,
                        new bytes(0)
                    ), // call data
                    new bytes(0), // user data
                    newCtx // ctx
                );
            } else {

                // delete flow to creator
                (newCtx, ) = _host.callAgreementWithContext(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.deleteFlow.selector,
                        _acceptedToken,
                        address(this),
                        creator,
                        new bytes(0)
                    ),
                    new bytes(0),
                    ctx
                );

                // delete flow to treasury
                (newCtx, ) = _host.callAgreementWithContext(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.deleteFlow.selector,
                        _acceptedToken,
                        address(this),
                        treasury,
                        new bytes(0)
                    ), // call data
                    new bytes(0), // user data
                    newCtx // ctx
                );

                streaming = false;
            }
        } else if (!streaming) {

            // open flow to creator
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.createFlow.selector,
                    _acceptedToken,
                    creator,
                    contract2creator,
                    new bytes(0)
                ),
                new bytes(0),
                ctx
            );

            // open flow to treasury
            (newCtx, ) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.createFlow.selector,
                    _acceptedToken,
                    treasury,
                    contract2treasury,
                    new bytes(0)
                ),
                new bytes(0),
                newCtx
            );

            streaming = true;
        }
    }

    // -----------------------------------------
    // Superfluid Callbacks
    // -----------------------------------------

    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata ctx
    )
        external view override
        onlyHost
        onlyExpected(superToken, agreementClass)
        returns (bytes memory cbdata)
    {
        cbdata = new bytes(0);
    }

    function afterAgreementCreated(
        ISuperToken /* superToken */,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata /*agreementData*/,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        return _subscribe(ctx, agreementClass, agreementId, cbdata);
    }

    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external view override
        onlyHost
        onlyExpected(superToken, agreementClass)
        returns (bytes memory cbdata)
    {
        cbdata = new bytes(0);
    }

    function afterAgreementUpdated(
        ISuperToken /* superToken */,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata /*agreementData*/,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        return _updateSubscribe(ctx, agreementClass, agreementId, cbdata);
    }

    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external view override
        onlyHost
        returns (bytes memory cbdata)
    {
        // According to the app basic law, we should never revert in a termination callback
        if (!_isSameToken(superToken) || !_isCFAv1(agreementClass)) return abi.encode(true);
        return abi.encode(false);
    }

    function afterAgreementTerminated(
        ISuperToken /* superToken */,
        address /* agreementClass */,
        bytes32 /* agreementId */,
        bytes calldata /*agreementData*/,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        // According to the app basic law, we should never revert in a termination callback
        (bool shouldIgnore) = abi.decode(cbdata, (bool));
        if (shouldIgnore) return ctx;
        return _unsubscribe(ctx);
    }

    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(_acceptedToken);
    }

    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType()
            == keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    }

    // -----------------------------------------
    // Modifiers
    // -----------------------------------------

    modifier onlyHost() {
        require(msg.sender == address(_host), "LotterySuperApp: support only one host");
        _;
    }

    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "LotterySuperApp: not accepted token");
        require(_isCFAv1(agreementClass), "LotterySuperApp: only CFAv1 supported");
        _;
    }

    modifier isCreator() {
        require(msg.sender == creator, "Not owner");
        _;
    }

}
