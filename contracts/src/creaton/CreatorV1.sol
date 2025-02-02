// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma abicoder v2;

import './ICreatonAdmin.sol';
import './NFTFactory.sol';
import './Post.sol';
import "../dependency/gsn/contracts/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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


import { Int96SafeMath } from "../utils/Int96SafeMath.sol";


contract CreatorV1 is SuperAppBase, Initializable, BaseRelayRecipient {
    using Int96SafeMath for int96;
    // -----------------------------------------
    // Errors
    // -----------------------------------------

    string private constant _ERR_STR_LOW_FLOW_RATE = "Superfluid: flow rate not enough";

    // -----------------------------------------
    // Structures
    // -----------------------------------------

    enum Status { unSubscribed, requestSubscribe, pendingSubscribe, pendingUnsubscribe, subscribed }
    enum Approval { neutral, like, dislike }
    enum Type {free, encrypted}

    event SubscriberEvent(address user, string pubKey, Status status);
    event Like(address user, uint256 tokenId, Approval approval);
    event NewPost(uint256 tokenId, string jsonData, Type contentType);
    event PostContract(address nftContract);

    struct Subscriber {
        Status status;
    }

    // -----------------------------------------
    // Storage
    // -----------------------------------------

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token

    address public admin;
    address public creator;
    ICreatonAdmin adminContract;
    NFTFactory nftFactory;

    string public description;
    int96 public subscriptionPrice;
    int96 private _MINIMUM_FLOW_RATE;
    mapping (address => Subscriber) public subscribers;
    uint256 subscriberCount; // subscribers in subscribed/pendingSubscribe state
    address public postNFT;
    mapping (uint256 => Type) post2tier;

    // -----------------------------------------
    // Initializer
    // -----------------------------------------

    function initialize(
        address host,
        address cfa,
        address acceptedToken,
        address _creator,
        string memory _description,
        uint256 _subscriptionPrice,
        string memory nftName,
        string memory nftSymbol
    ) public payable initializer {
        admin = msg.sender;

        assert(address(host) != address(0));
        assert(address(cfa) != address(0));
        assert(address(acceptedToken) != address(0));

        _host = ISuperfluid(host);
        _cfa = IConstantFlowAgreementV1(cfa);
        _acceptedToken = ISuperToken(acceptedToken);
        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL;
        _host.registerApp(configWord);

        creator = _creator;
        description = _description;
        subscriptionPrice = int96(uint96(_subscriptionPrice));
        _MINIMUM_FLOW_RATE = subscriptionPrice.mul(1e18).div(3600 * 24 * 30);

        adminContract = ICreatonAdmin(admin);
        nftFactory = NFTFactory(adminContract.nftFactory());
        createPostNFT(nftName, nftSymbol);
    }

    // -----------------------------------------
    // Logic
    // -----------------------------------------

    receive() external payable {}

    function withdrawEth() public onlyCreator {
        (bool success, ) = _msgSender().call{value: (address(this).balance)}("Not admin");
        require(success, "No balance");
    }

     function recoverTokens(address _token) external onlyCreator {
         IERC20(_token).approve(address(this), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
         IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
     }

    function changeStatus(address _address, Status status) private {
        subscribers[_address].status = status;
        emit SubscriberEvent(_address, "", status);
    }

    // TODO require subscriber is not subscribes already (sth like that)
    function requestSubscribe(string memory _pubKey) public {
        address _address = _msgSender();
        require(adminContract.registeredUsers(_address), "You need to signup in Creaton first");
        require (subscribers[_address].status == Status.unSubscribed, "Subscription Already Requested");
        subscribers[_address] = Subscriber(Status.requestSubscribe);
        emit SubscriberEvent(_address, _pubKey, Status.requestSubscribe);
    }

    function revokeSubscribe() external onlyCreator {
        address _address = _msgSender();
        require(subscribers[_address].status == Status.requestSubscribe ||
            subscribers[_address].status == Status.pendingSubscribe, "No Subscription Request to Revoke");
        changeStatus(_address, Status.unSubscribed);
        delete subscribers[_address];
    }

    function acceptSubscribe(address _address) external onlyCreator {
        require(subscribers[_address].status == Status.requestSubscribe, "No subscription requested");
        changeStatus(_address, Status.pendingSubscribe);
    }

    function blockSubscription(address _address) external onlyCreator {
        require(subscribers[_address].status != Status.unSubscribed, "Can't Block Unsubscribed Users");
        changeStatus(_address, Status.unSubscribed);
        delete subscribers[_address];
    }

    function bulkAcceptSubscribe(address[] memory _addresses) external onlyCreator {
        for(uint i = 0; i < _addresses.length; i++) {
            require(subscribers[_addresses[i]].status == Status.requestSubscribe, "No Subscription Requested");
            changeStatus(_addresses[i], Status.pendingSubscribe);
        }
    }

    function bulkBlockSubscription(address[] memory _addresses) external onlyCreator {
        for(uint i = 0; i < _addresses.length; i++) {
            require(subscribers[_addresses[i]].status != Status.unSubscribed, "Can't Block Unsubscribed Users");
            changeStatus(_addresses[i], Status.unSubscribed);
            delete subscribers[_addresses[i]];
        }
    }

    function getSubscriberCount() public view returns (uint256) {
        return subscriberCount;
    }

    function like(uint _tokenId, uint approvalEnum) public {
        require(postNFT != address(0));
        require(Post(postNFT).exists(_tokenId));
        address subAddress = _msgSender();
        require(adminContract.registeredUsers(subAddress), "You need to signup before liking content");
        if (post2tier[_tokenId] == Type.encrypted) {
            require(subscribers[subAddress].status == Status.subscribed, "Not subscribed");
        }
        require(approvalEnum < 3 && approvalEnum >= 0, "Invalid approval enum");
        Approval approval = Approval(approvalEnum);
        emit Like(subAddress, _tokenId, approval);
    }

    function createPostNFT(string memory name, string memory symbol) internal {
        require(postNFT == address(0));
        postNFT = nftFactory.createPostNFT(name, symbol, "", address(this));
        emit PostContract(postNFT);
    }

    function upload(string memory _metadataURI, string memory _dataJSON, Type contentType) external onlyCreator {
        require(postNFT != address(0));
        require(contentType ==  Type.free || contentType == Type.encrypted);
        uint256 tokenId = Post(postNFT).mint(creator, _metadataURI);
        post2tier[tokenId] = contentType;
        emit NewPost(tokenId, _dataJSON, contentType);
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

    function versionRecipient() external view override  returns (string memory){
        return "2.1.0";
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == adminContract.getTrustedForwarder();
    }

    // -----------------------------------------
    // Superfluid Logic
    // -----------------------------------------

    function _openFlows(
        bytes calldata ctx,
        int96 contract2creator, 
        int96 contract2treasury
    ) private returns (bytes memory newCtx){
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
                    adminContract.treasury(),
                    contract2treasury,
                    new bytes(0)
                ),
                new bytes(0),
                newCtx
            );
    }

    function _updateFlows(
        bytes calldata ctx,
        int96 contract2creator, 
        int96 contract2treasury
    ) private returns (bytes memory newCtx){
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
                adminContract.treasury(),
                contract2treasury,
                new bytes(0)
            ), // call data
            new bytes(0), // user data
            newCtx // ctx
        );
    }

    function _deleteFlows(
        bytes calldata ctx
    ) private returns (bytes memory newCtx) {
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
                adminContract.treasury(),
                new bytes(0)
            ), // call data
            new bytes(0), // user data
            newCtx // ctx
        );
    }

    function _addSubscriber(address _address) private {
        subscriberCount += 1;
        changeStatus(_address, Status.subscribed);
    }

    function _delSubscriber(address _address) private {
        subscriberCount -= 1;
        changeStatus(_address, Status.unSubscribed);
        delete subscribers[_address];
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
        require(subscribers[context.msgSender].status == Status.pendingSubscribe, "Subscription not Granted");

        int96 contractFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
        int96 contract2creatorDelta = percentage(contractFlowRate, adminContract.treasuryFee());
        int96 contract2treasuryDelta = contractFlowRate.sub(contract2creatorDelta);

        if (subscriberCount == 0){
            newCtx = _openFlows(ctx, contract2creatorDelta, contract2treasuryDelta);
        } else if (subscriberCount > 0){
            (, int96 contract2creatorCurrent, , ) = _cfa.getFlow(_acceptedToken, address(this), creator);
            (, int96 contract2treasuryCurrent, , ) = _cfa.getFlow(_acceptedToken, address(this), adminContract.treasury());
            newCtx = _updateFlows(ctx,
                                contract2creatorCurrent + contract2creatorDelta, 
                                contract2treasuryCurrent + contract2treasuryDelta
                                );
        }

        _addSubscriber(context.msgSender);
    }

    function _updateSubscribe(
        bytes calldata ctx,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata cbdata
    ) private returns (bytes memory newCtx){

        (, int96 flowRate, , ) = IConstantFlowAgreementV1(agreementClass).getFlowByID(_acceptedToken, agreementId);
        require(flowRate >= _MINIMUM_FLOW_RATE, _ERR_STR_LOW_FLOW_RATE);

        int96 contractFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
        int96 contract2creatorDelta = percentage(contractFlowRate, adminContract.treasuryFee());
        int96 contract2treasuryDelta = contractFlowRate.sub(contract2creatorDelta);

        (, int96 contract2creatorCurrent, , ) = _cfa.getFlow(_acceptedToken, address(this), creator);
        (, int96 contract2treasuryCurrent, , ) = _cfa.getFlow(_acceptedToken, address(this), adminContract.treasury());
        newCtx = _updateFlows(ctx,
                              contract2creatorCurrent + contract2creatorDelta, 
                              contract2treasuryCurrent + contract2treasuryDelta
                             );
    }

    function _unsubscribe (
        bytes calldata ctx
    ) private returns (bytes memory newCtx){
        address sender = _host.decodeCtx(ctx).msgSender;
        if (subscriberCount == 1){
            newCtx = _deleteFlows(ctx);
        } else if (subscriberCount > 0){
            int96 contractFlowRate = _cfa.getNetFlow(_acceptedToken, address(this));
            int96 contract2creatorDelta = percentage(contractFlowRate, adminContract.treasuryFee());
            int96 contract2treasuryDelta = contractFlowRate.sub(contract2creatorDelta);

            (, int96 contract2creatorCurrent, , ) = _cfa.getFlow(_acceptedToken, address(this), creator);
            (, int96 contract2treasuryCurrent, , ) = _cfa.getFlow(_acceptedToken, address(this), adminContract.treasury());

            newCtx = _updateFlows(ctx,
                                  contract2creatorCurrent + contract2creatorDelta, 
                                  contract2treasuryCurrent + contract2treasuryDelta
                                 );
        }

        _delSubscriber(sender);
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
        bytes32 agreementId,
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

    modifier onlyCreator() {
        require(_msgSender() == creator, "Not the creator");
        _;
    }

}
