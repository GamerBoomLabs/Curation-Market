# Bonding Curve for Curation Market
GamerBoom is a Web3 gaming portal built on popular Web2 games like League of Legends. It helps gamers tokenize their intrinsic value, offering a seamless gaming experience with diverse Web3 features, including decentralization, trustlessness, crypto incentives, etc.

# Curation Market: Where Gaming Meets Web3
Our current product matrix primarily consists of two parts: Web3 Portal Clieant and Curation Market. The GamerBoom Portal Client is tailored to provide traditional gamers with effortless access to the Web3 realm, allowing them to earn rewards while gaming without disrupting their gaming experience. In contrast, the Curation Market is a decentralized curation protocol based on a bonding curve mechanism. It is designed to provide a tokenization and curation mechanism for all intangible assets like influence, items, UGC, gaming data, etc.

# Basic Contracts Interaction Flow of Curation Market
The basic logic of the Curation Market involves introducing a dynamic bonding curve to create a dedicated bonding pool for any intangible asset (such as gaming influencers, items, IP, game data, etc.). This allows the intrinsic value of these intangible assets to be tokenized, traded, and even developed into financial derivatives. Holding the bonding pool's share token (BLP) represents a user's recomendation, or curation, of the intangible asset. Additionally, a portion of all revenue related to the intangible asset is automatically added to the bonding pool as reserves, enhancing the liquidity of the share token (BLP).

This repository contains a set of Solidity smart contracts and an interaction diagram that explains the relationships between them. The diagram illustrates the order of contract deployment, the interactions between the different contracts, and the internal functions of each contract.

You can view the UML diagram below:

![Contract Interaction Flow](./ContractsInteractionFlow.drawio.svg)

Please note that the diagram is a simplified representation of the contract interactions and may not include all the details. For a complete understanding, please review the Solidity source code files in the contracts directory.

