/* globals artifacts */
const ParaswapParams = artifacts.require('./paraswap/ParaswapParams.sol')
const GetBancorAddressFromRegistry = artifacts.require('./bancor/GetBancorAddressFromRegistry.sol')
const GetRatioForBancorAssets = artifacts.require('./bancor/GetRatioForBancorAssets.sol')


const SmartFundRegistry = artifacts.require('./core/SmartFundRegistry.sol')
const ExchangePortal = artifacts.require('./core/ExchangePortal.sol')
const PermittedExchanges = artifacts.require('./core/PermittedExchanges.sol')
const PermittedPools = artifacts.require('./core/PermittedPools.sol')
const PoolPortal = artifacts.require('./core/PoolPortal.sol')


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

    .then(() => deployer.deploy(PermittedPools, PoolPortal.address))

    .then(() => deployer.deploy(ExchangePortal,
      PARASWAP_NETWORK_ADDRESS,
      PRICE_FEED_ADDRESS,
      ParaswapParams.address,
      GetBancorAddressFromRegistry.address,
      BANCOR_ETH_WRAPPER,
      GetRatioForBancorAssets.address
    ))
    .then(() => deployer.deploy(PermittedExchanges, ExchangePortal.address))

    .then(() => deployer.deploy(
      SmartFundRegistry,
      PLATFORM_FEE,
      ExchangePortal.address,
      PermittedExchanges.address,
      PermittedPools.address,
      PoolPortal.address
    ))
}
