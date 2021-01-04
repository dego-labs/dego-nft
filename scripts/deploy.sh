echo "deploy begin....."

TF_CMD=node_modules/.bin/truffle-flattener


# echo "" >  ./deployments/NFTMarket.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTMarket.full.sol
# $TF_CMD ./contracts/market/NFTMarket.sol >>  ./deployments/NFTMarket.full.sol 


# echo "" >  ./deployments/NFTMarketProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTMarketProxy.full.sol
# $TF_CMD ./contracts/market/NFTMarketProxy.sol >>  ./deployments/NFTMarketProxy.full.sol 

# echo "" >  ./deployments/NFTRewardALPA1.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA1.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA1.sol >>  ./deployments/NFTRewardALPA1.full.sol 

# echo "" >  ./deployments/NFTRewardALPA1Proxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA1Proxy.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA1Proxy.sol >>  ./deployments/NFTRewardALPA1Proxy.full.sol 

# echo "" >  ./deployments/NFTRewardALPA2.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA2.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA2.sol >>  ./deployments/NFTRewardALPA2.full.sol 

# echo "" >  ./deployments/NFTRewardALPA2Proxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA2Proxy.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA2Proxy.sol >>  ./deployments/NFTRewardALPA2Proxy.full.sol 


# CONTRACT_LIST=(GegoArt GegoArtFactory GegoArtFactoryProxy)

# for contract in ${CONTRACT_LIST[@]};
# do
#     echo $contract
#     echo "" >  ./deployments/$contract.full.sol
#     cat  ./scripts/head.sol >  ./deployments/$contract.full.sol
#     $TF_CMD ./contracts/art/$contract.sol >>  ./deployments/$contract.full.sol 
# done


# $TF_CMD ./contracts/test/StorageProxy.sol >  ./deployments/StorageProxy.full.sol 
# $TF_CMD ./contracts/test/Storage.sol >  ./deployments/Storage.full.sol 

# echo "" >  ./deployments/ChristmasClaim.full.sol
# cat  ./scripts/head.sol >  ./deployments/ChristmasClaim.full.sol
# $TF_CMD ./contracts/christmas/ChristmasClaim.sol >>  ./deployments/ChristmasClaim.full.sol 

# echo "" >  ./deployments/ChristmasClaimProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/ChristmasClaimProxy.full.sol
# $TF_CMD ./contracts/christmas/ChristmasClaimProxy.sol >>  ./deployments/ChristmasClaimProxy.full.sol 

# echo "" >  ./deployments/GegoChristmasClaimProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/GegoChristmasClaimProxy.full.sol
# $TF_CMD ./contracts/christmas/GegoChristmasClaimProxy.sol >>  ./deployments/GegoChristmasClaimProxy.full.sol 

# echo "" >  ./deployments/GegoChristmasClaimProxyProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/GegoChristmasClaimProxyProxy.full.sol
# $TF_CMD ./contracts/christmas/GegoChristmasClaimProxyProxy.sol >>  ./deployments/GegoChristmasClaimProxyProxy.full.sol 

echo "" >  ./deployments/NFTMarketV2.full.sol
cat  ./scripts/head.sol >  ./deployments/NFTMarketV2.full.sol
$TF_CMD ./contracts/market/NFTMarketV2.1.sol >>  ./deployments/NFTMarketV2.full.sol 

# rm *_sol_*

echo "deploy end....."