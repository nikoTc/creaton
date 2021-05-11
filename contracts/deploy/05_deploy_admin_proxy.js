const func = async function (hre) {
  let {admin, treasury} = await hre.getNamedAccounts();
  const {ethers, deployments, upgrades} = hre;
  const {deploy, execute} = deployments;
  // const useProxy = !hre.network.live;

  const SuperfluidSDK = require('@superfluid-finance/js-sdk');


  const sf = new SuperfluidSDK.Framework({
    chainId: 5,
    version: 'v1',
    web3Provider: await hre.web3.currentProvider,
    tokens: ['fUSDC'],
  });
  await sf.initialize();

  // TODO don't forget to change this on demand
  const trustedforwarder = "0xE041608922d06a4F26C0d4c27d8bCD01daf1f792"
  const beaconContract = await hre.deployments.get("CreatorBeacon")
  const nftFactory = await hre.deployments.get("NFTFactory")
  const paymasterContract = await hre.deployments.get("CreatonPaymaster")
  const treasuryFee = 90;
  const usdcx = sf.tokens.fUSDCx;

  const CreatonAdmin = await ethers.getContractFactory("CreatonAdmin");

  let adminContract = await upgrades.deployProxy(
    CreatonAdmin,
    [
      sf.host.address,
      sf.agreements.cfa.address,
      usdcx.address,
      treasury,
      treasuryFee,
      beaconContract.address,
      nftFactory.address,
      trustedforwarder,
      paymasterContract.address
    ],
    {kind: 'uups'}
  );

  console.log('Add creaton admin to paymaster')
  let relayHubReceipt = await execute(
      'CreatonPaymaster',
      {from: admin},
      "setAdmin",
      adminContract.address);
  console.log(relayHubReceipt.transactionHash);

}
