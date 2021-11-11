Github Actions - develop | [![](https://github.com/dodopontocom/darcano/actions/workflows/testnet.yml/badge.svg?branch=terraforming)](https://github.com/dodopontocom/darcano/actions/workflows/testnet.yml) |
--- | --- |

# darcano
It is an anagram for [Cardano](https://developers.cardano.org/)  

# Implementations/Backlog/Todo's

- [x] Create keys/certifications/addresses for testnet
- [x] Cardano StakePool Infra as Code  
- [x] Setup Telegram in both Relay and BP nodes    
- [x] Telegram command to reply BP Processed Tx  
- [ ] (Telegram) Send Block Leader Prediction  
- [ ] Develop Self-update Cardano-node script  
- [ ] (Telegram) Develop commands to check metrics (prometheus)  
- [ ] (Telegram) Develop commands to check basic servers info  
- [ ] Dockerization  
- [ ] (terraform) Support AWS  
- [ ] Make all scripts support switch to mainnet and vice-versa (depends on keys/certifications/addresses creation for mainnet)  

### Cardano Stake Pool on Testnet
This repo will maintain scripts and miscellaneous regarding setting up a Stake Pool in Cardano TestNet.  
This will be implemented on cloud based infrastructure and automated as much as possible. Maybe multi-cloud but for now mostly in [GCP](https://cloud.google.com/products).

### Stake Pool
https://developers.cardano.org/docs/operate-a-stake-pool/  
https://cardano.org/stake-pool-operation/

### TestNet
https://testnets.cardano.org/en/testnets/cardano/overview/  
https://developers.cardano.org/docs/get-started/testnets-and-devnets

### Guides and References
https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node  
https://medium.com/cardanorss/a-guide-to-becoming-a-stake-pool-operator-36a28c00c9e0  
https://developers.cardano.org/docs/stake-pool-course/

- More references  
https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_versions  
https://github.com/dodopontocom/terraform-gcp-lab/blob/develop/.circleci/cicd-definitions.sh  
https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_from_machine_image  
https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_machine_image  
https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance  
https://github.com/roughentomologyx/gotty

### Ada
https://cardano.org/what-is-ada/

### Wallets
https://yoroi-wallet.com/#/  
https://daedaluswallet.io/

# Important
> # Warranty
> ***There is no warranty. Use at your own risk. The code is public and fully auditable by you, and its your responsibility to do so.***

# Donation
- Ada address  
addr1q8nsyv5g7engrm20rc28rxnvfae07lt3awentfhkpddnnle2t4kf2u8vntttsq2xj9vs8qms6sqm3j37tm3kcjhsy8nsr6q76a

![image](ada_my_address.png)

;)
