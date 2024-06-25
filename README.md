# GamerBoom: The Web3 Portal for Onboarding Billions of Gamers
GamerBoom is a Web3 gaming portal built on popular Web2 games like League of Legends. It helps gamers tokenize their intrinsic value, offering a seamless gaming experience with diverse Web3 features, including decentralization, trustlessness, crypto incentives, etc.

Official Links:  
🌐 Website: https://www.gamerboom.org/  
🎉 Discord: http://discord.gg/gamerboom  
🐦 Twitter: https://twitter.com/Gamerboom_  
📹 Official Trailer: https://www.youtube.com/watch?v=xD7w2uecug8  
📚 Official Wiki: https://gamerboom.gitbook.io/gamerboom-docs-v1.0  

# Coinbase Smart Wallet Integration
While we have developed a low-barrier overlay app based on traditional Web2 games to seamlessly onboard users, we still need a Web3 wallet solution with an even lower barrier to entry. This will enable Web2 users to easily and quickly create Web3 accounts. Therefore, we have decided to integrate Coinbase Smart Wallet to achieve this goal.

The no-private-key design of Coinbase Smart Wallet significantly reduces user education costs and the entry barrier, providing an experience very similar to traditional internet account systems. This will greatly benefit us. At the same time, we believe that our integration will bring a large number of new users to Coinbase Smart Wallet, promoting widespread adoption of both the wallet and the Base chain

# Curation Market: Where Gaming Meets Web3
Our current product matrix primarily consists of two parts: Web3 Portal Clieant and Curation Market. The GamerBoom Portal Client is tailored to provide traditional gamers with effortless access to the Web3 realm, allowing them to earn rewards while gaming without disrupting their gaming experience. In contrast, the Curation Market is a decentralized curation protocol based on a bonding curve mechanism. It is designed to provide a tokenization and curation mechanism for all intangible assets like influence, items, UGC, gaming data, etc.

# Basic Contracts Interaction Flow of Curation Market
The basic logic of the Curation Market involves introducing a dynamic bonding curve to create a dedicated bonding pool for any intangible asset (such as gaming influencers, items, IP, game data, etc.). This allows the intrinsic value of these intangible assets to be tokenized, traded, and even developed into financial derivatives. Holding the bonding pool's share token (BLP) represents a user's recomendation, or curation, of the intangible asset. Additionally, a portion of all revenue related to the intangible asset is automatically added to the bonding pool as reserves, enhancing the liquidity of the share token (BLP).

This repository contains a set of Solidity smart contracts and an interaction diagram that explains the relationships between them. The diagram illustrates the order of contract deployment, the interactions between the different contracts, and the internal functions of each contract.

You can view the UML diagram below:

![Contract Interaction Flow](./ContractsInteractionFlow.drawio.svg)

Please note that the diagram is a simplified representation of the contract interactions and may not include all the details. For a complete understanding, please review the Solidity source code files in the contracts directory.

