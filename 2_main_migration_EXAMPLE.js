/* globals artifacts */
const ParaswapParams = artifacts.require('./ParaswapParams.sol')
const SmartFundRegistry = artifacts.require('./SmartFundRegistry.sol')
const ExchangePortal = artifacts.require('./ExchangePortal.sol')
const PermittedExchanges = artifacts.require('./PermittedExchanges.sol')
const GetRatioForBancorAssets = artifacts.require('./GetRatioForBancorAssets.sol')
const PoolPortal = artifacts.require('./PoolPortal.sol')
const GetBancorAddressFromRegistry = artifacts.require('./GetBancorAddressFromRegistry.sol')

const PARASWAP_NETWORK_ADDRESS = ""
const PARASWAP_PRICE_ADDRESS = ""
const BANCOR_REGISTRY = ""
const BANCOR_ETH_WRAPPER = ""
const PRICE_FEED_ADDRESS = ""
const PLATFORM_FEE = 1000


module.exports = (deployer, network, accounts) => {
  deployer
    .then(() => deployer.deploy(ParaswapParams))
    .then(() => deployer.deploy(GetBancorAddressFromRegistry, BANCOR_REGISTRY))
    .then(() => deployer.deploy(GetRatioForBancorAssets, GetBancorAddressFromRegistry.address))
    .then(() => deployer.deploy(PoolPortal,
      GetBancorAddressFromRegistry.address,
      GetRatioForBancorAssets.address,
      BANCOR_ETH_WRAPPER
    ))
    .then(() => deployer.deploy(ExchangePortal,
      PARASWAP_NETWORK_ADDRESS,
      PRICE_FEED_ADDRESS,
      ParaswapParams.address,
      GetBancorAddressFromRegistry.address,
      BANCOR_ETH_WRAPPER
    ))
    .then(() => deployer.deploy(PermittedExchanges, ExchangePortal.address))
    .then(() => deployer.deploy(
      SmartFundRegistry,
      PLATFORM_FEE,
      ExchangePortal.address,
      PermittedExchanges.address,
      PoolPortal.address
    ))
}
