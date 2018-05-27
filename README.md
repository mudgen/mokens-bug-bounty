# Bug Bounty Program for the Mokens Contract

This bug bounty program applies to the [Mokens contract](Mokens.sol) in this repository.

I am willing to pay up to 1 ETH total for security vulnerabilities or other bugs found or for important gas optimizations. The amount of ETH paid for a bug found will depend on the severity and importance of the bug and the helpfullness of the bug report. No ETH will be paid for bugs that have been previously reported.

To report a bug create an issue in this repository about it.

Generally, any useful comments, about bugs or not, are appreciated.

The bug bounty starts now and ends on 30 May 2018 or potentially later than that.

To understand what mokens are about read the webpage about mokens here: https://mokens.io/about

Currently the beta version of the mokens website is running here: https://mokens.io/

## Understanding the Mokens Contract

The mokens contract implements the ERC721, ERC721Enumerable, ERC721Metadata and ERC165 interfaces.

The contract mints ERC721-based crypto-collectibles called "mokens".

The contract has been gas-optimized. Specifically the mint function has been optimized to require as little gas as possible while still implementing the needed functionality.

### TokenId and Index

Each moken has a tokenId that identifies it. tokenIds start at 0 and increment. The contract contains a list of all mokens via the `mapping (uint256 => Moken) private mokens;` mapping. 

### Burning/Deleting Mokens

You will notice that there is no burn/delete moken function in the contract. This functionality was left out because this functionality would require a mapping from tokenId to token index position which would add at least 20,000 more gas to the mint function and add gas other places. Keeping the tokenId the same as its index position in the list of all mokens reduces gas and simplifies the implementation of ERC721Enumerable. 

So the implementation of tokenByIndex is very simple:
```  
function tokenByIndex(uint256 _index) external view returns (uint256 tokenId) {
    require(_index < mokensLength, "TokenId at this index does not exist.");
    return _index;
}
```
I think most users will not want to delete/burn their mokens and when they do they can get rid of them by selling them or sending them to another ethereum address.








