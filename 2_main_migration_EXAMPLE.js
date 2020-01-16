/* globals artifacts */
const ParaswapParams = artifacts.require('./ParaswapParams.sol')
const SmartFundRegistry = artifacts.require('./SmartFundRegistry.sol')
const ExchangePortal = artifacts.require('./ExchangePortal.sol')
const PermittedExchanges = artifacts.require('./PermittedExchanges.sol')
const GetRatioForBancorAssets = artifacts.require('./GetRatioForBancorAssets.sol')
const PoolPortal = artifacts.require('./PoolPortal.sol')


const PARASWAP_NETWORK_ADDRESS = ""
const PARASWAP_PRICE_ADDRESS = ""
const BANCOR_REGISTRY = ""
const BANCOR_NETWORK_ADDRESS = ""
const BANCOR_PATH_FINDER_ADDRESS = ""
const PRICE_FEED_ADDRESS = ""
const PLATFORM_FEE = 1000


module.exports = (deployer, network, accounts) => {
  deployer
    .then(() => deployer.deploy(ParaswapParams))
    .then(() => deployer.deploy(GetRatioForBancorAssets, BANCOR_NETWORK_ADDRESS, BANCOR_PATH_FINDER_ADDRESS))
    .then(() => deployer.deploy(PoolPortal, BANCOR_REGISTRY, GetRatioForBancorAssets.address))
    .then(() => deployer.deploy(ExchangePortal, PARASWAP_NETWORK_ADDRESS, PRICE_FEED_ADDRESS, ParaswapParams.address, PoolPortal.address))
    .then(() => deployer.deploy(PermittedExchanges, ExchangePortal.address))
    .then(() =>
      deployer.deploy(
        SmartFundRegistry,
        PLATFORM_FEE,
        ExchangePortal.address,
        PermittedExchanges.address,
      )
    )
}
