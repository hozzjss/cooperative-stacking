# Decent Delegate
Decent Decentralized Decentralizedadized

## Intro
PoX is a novel consensus algorithm, which takes bitcoin from miners and gives to stackers


**Miners** instead of burning bitcoin they send these bitcoins to **Stackers** who lock their STX to support network security.


Smart contracts can be 1st class **stackers** and that while it might seem a simple idea in the beginning it's quite an underused feature, with so much potential

- Electing a btc address for rewards
- Having a controlled pool (different from delegating) where logic rules supreme
- Having funds for different causes one case of which can be collective student loan forgiveness contract which could collect a 100 STX from all participant and circulate rewards between all participants' btc addresses
- Collateralized pools where a stacker would pledge payment of X and provide half of X in STX in the beginning so that if they decide not to payout the remaining of the pledge the delegator would get half of that reward (whether early or after the cycle ends).
- Mutual funds for communities who want to collectively support each other with BTC instead of one whale having so much STX the community can collectively have a large amount of STX pooling it together and using the BTC for whichever community projects they aspire to.


**Decent delegate is a just a use case of many cases where logic would define how we use this novel algorithm**


This is a work in progress open source project and any contributions are welcome, there's a grant request open here [DecentDelegate Grant](https://github.com/stacksgov/Stacks-Grants/issues/69)


## Flow

- A **Stacker** deploys this contract
- A **Stacker** would call `create-decent-pool` with parameters for that pool
- **Delegators** would keep virtually delegating by depositing funds into the contract
- Multiple **Delegators** can delegate to the pool
- A delegator can only increase their stake
- There's no going back except if the lock expires or the lock cycle/s complete
- After one of these events happen 
- The stacking cycle starts once the pool is full of the fixed required amount
- The delegator might only send amounts larger than `minimum-delegator-stake` set in creation
- When stacking begins a **Stacker**  would get rewards into the `pox-address` they specified
- Stacker would have put collateral against their pledged rewards in STX
- That collateral can be taken from at any time by the delegators and at first they won't be able to withdraw the rest of their rewards later on
- The stacking cycle ends when the 
 