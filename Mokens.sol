pragma solidity 0.4.24;

contract Test {
    
    Mokens mokens = Mokens(0xbA8dC1a692093d8aBD34e12aa05a4fE691121bB6);
    uint256 public tokenId;
    function mint(string name) external {
        tokenId = mokens.contractMint(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c, name, 0xca35b7d915458ef540ade6068dfe2f44e8fa733cca35b7d915458ef540ade606, 0x636f6f6c636f696e, 10);
    }
}

contract ERC721Receiver {
    /// @dev Magic value to be returned upon successful reception of an NFT
    ///  Equals to bytes4(keccak256("onERC721Received(address,uint256,bytes)"))
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `safetransfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address 
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns (bytes4);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _to, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address _operator);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) external view returns (uint256);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
interface ERC721Metadata {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param _interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `_interfaceID` and
    ///  `_interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract Mokens is ERC721, ERC721Enumerable, ERC721Metadata, ERC165 {
    uint256 public blockNum;

    /* Constructor ***********************************************************/
    constructor() public {

        blockNum = block.number;

        //Management
        manager = msg.sender;
        startNextEra_("Genesis");

    }
    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC165Impl ***********************************************************/
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return _interfaceID == 0x01ffc9a7  //ERC165
            || _interfaceID == 0x80ac58cd  //ERC721
            || _interfaceID == 0x5b5e139f  //ERC721Metadata
            || _interfaceID == 0x780e9d63; //ERC721Enumerable
    }
    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Token Data ***********************************************************/
    struct Moken {
        string name;
        uint256 dataHash;
    }
    //tokenId to moken
    mapping (uint256 => Moken) private mokens;
    uint256 private mokensLength = 0;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint32[]) private ownedTokens;

    uint256 constant UINT16_MASK = 0x000000000000000000000000000000000000000000000000000000000000ffff;
    uint256 constant MOKEN_DATA_MASK = 0xffffffffffffffff000000000000000000000000000000000000000000000000;
    uint256 constant MOKEN_HASH_MASK = 0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant MAX_MOKENS = 4294967296;
    uint256 constant MAX_OWNER_MOKENS = 65536;

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Contract Management ***********************************************************/
    address public manager;
    address public contractManager = address(0);
    
    // Mapping from token ID to approved address
    mapping (uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private operatorApprovals;

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == contractManager, "Must be the manager.");
        _;
    }

    modifier onlyApproved(uint256 _tokenId) {
        address owner = address(mokens[_tokenId].dataHash);
        require(owner != address(0), "The tokenId does not exist.");
        require(msg.sender == owner || tokenApprovals[_tokenId] == msg.sender || operatorApprovals[owner][msg.sender],
            "Must be the owner or approved to take this action.");
        _;
    }

    function withdraw(address _sendTo, uint256 _amount) external onlyManager {
        address mokensContract = this;
        if (_amount > mokensContract.balance) {
            _sendTo.transfer(mokensContract.balance);
        } else {
            _sendTo.transfer(_amount);
        }

    }
    
    function setManager(address _manager) external onlyManager {
        if(isContract(_manager) || _manager == address(0)) {
            contractManager = _manager;
        }
        else {
            manager = _manager;
        }
    }
    

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721Impl ***********************************************************/

    // Equals to bytes4(keccak256("onERC721Received(address,uint256,bytes)"))
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    function balanceOf(address _owner) external view returns (uint256 totalMokensOwned) {
        require(_owner != address(0), "Owner cannot be the 0 address.");
        return ownedTokens[_owner].length;
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = address(mokens[_tokenId].dataHash);
        require(owner != address(0), "The tokenId does not exist.");
        return owner;
    }

    function approve(address _to, uint256 _tokenId) external {
        address owner = address(mokens[_tokenId].dataHash);
        require(owner != address(0), "The tokenId does not exist.");
        require(msg.sender == owner || operatorApprovals[owner][msg.sender], "Must be the owner or approved operator.");

        if (tokenApprovals[_tokenId] != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    function getApproved(uint256 _tokenId) external view returns (address approvedAddress) {
        address owner = address(mokens[_tokenId].dataHash);
        require(owner != address(0), "The tokenId does not exist.");
        return tokenApprovals[_tokenId];
    }


    function setApprovalForAll(address _to, bool _approved) external {
        require(_to != address(0), "Cannot set a 0 address.");
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool approved) {
        return operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external onlyApproved(_tokenId) {
        clearApprovalAndTransfer(_from, _to, _tokenId, "", false);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external onlyApproved(_tokenId) {
        clearApprovalAndTransfer(_from, _to, _tokenId, "", true);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external onlyApproved(_tokenId) {
        clearApprovalAndTransfer(_from, _to, _tokenId, _data, true);
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId, bytes _data, bool _safe) private {
        require(_from != address(0), "_from cannot be the 0 address.");
        require(_to != address(0), "_to cannot be the 0 address.");
        uint256 dataHash = mokens[_tokenId].dataHash;
        address owner = address(dataHash);
        require(owner == _from, "The tokenId is not owned by _from.");

        //Clear approval
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_from, address(0), _tokenId);
        }

        //removing the tokenId
        // 1. We replace _tokenId in ownedTokens[_from] with the last token id
        //    in ownedTokens[_from]
        uint256 lastTokenIndex = ownedTokens[_from].length - 1;
        uint256 lastTokenId = ownedTokens[_from][lastTokenIndex];
        uint256 tokenIndex = dataHash >> 160 & UINT16_MASK;
        ownedTokens[_from][tokenIndex] = uint32(lastTokenId);
        // 2. We remove lastTokenId from the end of ownedTokens[_from]
        ownedTokens[_from].length--;
        // 3. We set lastTokeId to point to its new position in ownedTokens[_from]
        uint256 lastTokenIdDataHash = mokens[lastTokenId].dataHash;
        mokens[lastTokenId].dataHash = lastTokenIdDataHash & 0xffffffffffffffffffff0000ffffffffffffffffffffffffffffffffffffffff | tokenIndex << 160;

        //adding the tokenId
        uint256 ownedTokensLength = ownedTokens[_to].length;
        // prevents 16 bit overflow
        require(ownedTokensLength < MAX_OWNER_MOKENS, "An single owner address cannot possess more than 65,536 mokens.");
        mokens[_tokenId].dataHash = dataHash & 0xffffffffffffffffffff00000000000000000000000000000000000000000000 | ownedTokensLength << 160 | uint256(_to);
        ownedTokens[_to].push(uint32(_tokenId));

        emit Transfer(_from, _to, _tokenId);

        if (_safe) {
            if(isContract(_to)) {
                bytes4 val = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
                require(val == ERC721_RECEIVED, "The receiving contract must be able to receive this token.");
            }
        }
    }


    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721EnumerableImpl **************************************************/

    function exists(uint256 _tokenId) external view returns (bool) {
        return _tokenId < mokensLength;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId) {
        require(_index < ownedTokens[_owner].length, "Owner does not own a token at this index.");
        return ownedTokens[_owner][_index];
    }

    function totalSupply() external view returns (uint256 totalMokens) {
        return mokensLength;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256 tokenId) {
        require(_index < mokensLength, "Token at this index does not exist.");
        return _index;
    }
    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* ERC721MetadataImpl **************************************************/
    string constant name_ = "Mokens";
    string constant symbol_ = "MKN";

    function name() external pure returns (string) {
        return name_;
    }

    function symbol() external pure returns (string) {
        return symbol_;
    }

    mapping (uint256 => string) private tokenURI_;

    string private defaultURLStart = "https://api.mokens.io/moken/";
    string private defaultURLEnd = ".json";

    function setDefaultURLStart(string _defaultURLStart) external onlyManager {
        defaultURLStart = _defaultURLStart;
    }

    function setDefaultURLEnd(string _defaultURLEnd) external onlyManager {
        defaultURLEnd = _defaultURLEnd;
    }

    function setTokenURI(uint256 _tokenId, string _uri) external onlyApproved(_tokenId) {
        tokenURI_[_tokenId] = _uri;
    }

    function deleteCustomTokenURI(uint256 _tokenId) external onlyApproved(_tokenId) {
        delete tokenURI_[_tokenId];
    }

    function hasCustomURI(uint256 _tokenId) external view returns (bool) {
        require(_tokenId < mokensLength, "The tokenId does not exist.");
        return bytes(tokenURI_[_tokenId]).length > 0;
    }

    function tokenURI(uint256 _tokenId) external view returns (string tokenURIString) {
        require(_tokenId < mokensLength, "The tokenId does not exist.");
        if(bytes(tokenURI_[_tokenId]).length == 0) {
            return makeIntString(defaultURLStart,_tokenId,defaultURLEnd);
        }
        else {
            return tokenURI_[_tokenId];
        }
    }

    // creates a string made from an integer between two strings
    function makeIntString(string startString, uint256 v, string endString) private pure returns (string) {
        uint256 maxlength = 10;
        bytes memory reversed = new bytes(maxlength);
        uint256 numDigits = 0;
        if(v == 0) {
            numDigits = 1;
            reversed[0] = byte(48);
        }
        else {
            while (v != 0) {
                uint256 remainder = v % 10;
                v = v / 10;
                reversed[numDigits++] = byte(48 + remainder);
            }
        }
        bytes memory startStringBytes = bytes(startString);
        bytes memory endStringBytes = bytes(endString);
        uint256 startStringLength = startStringBytes.length;
        uint256 endStringLength = endStringBytes.length;
        bytes memory newStringBytes = new bytes(startStringLength + numDigits + endStringLength);
        uint256 i;
        for (i = 0; i < startStringLength; i++) {
            newStringBytes[i] = startStringBytes[i];
        }
        for (i = 0; i < numDigits; i++) {
            newStringBytes[i + startStringLength] = reversed[numDigits - 1 - i];
        }
        for (i = 0; i < endStringLength; i++) {
            newStringBytes[i + startStringLength + numDigits] = endStringBytes[i];
        }
        return string(newStringBytes);
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Eras  **************************************************/

    event NewEra(
        uint256 index,
        bytes32 name,
        uint256 startTokenId
    );


    mapping (uint256 => bytes32) private eras;
    uint256 private eraLength = 0;

    mapping (bytes32 => uint256) private eraIndex;

    function startNextEra_(bytes32 _eraName) private returns (uint256 index, uint256 startTokenId) {
        require(_eraName != 0, "eraName is empty string.");
        require(eraIndex[_eraName] == 0, "Era name already exists.");
        startTokenId = mokensLength;
        index = eraLength++;
        eras[index] = _eraName;
        eraIndex[_eraName] = index+1;
        emit NewEra(index, _eraName, startTokenId);
        return (index, startTokenId);
    }

    function startNextEra(bytes32 _eraName,  uint256 _mintBasePrice) external onlyManager returns (uint256 index, uint256 startTokenId) {
        setMintBasePrice_(_mintBasePrice);
        return startNextEra_(_eraName);
    }

    function startNextEra(bytes32 _eraName) external onlyManager returns (uint256 index, uint256 startTokenId) {
        return startNextEra_(_eraName);
    }

    
    function eraByIndex(uint256 _index) external view returns(bytes32 era) {
        require(_index < eraLength, "No era at this index.");
        return eras[_index];
    }

    
    function eraByName(bytes32 _eraName) external view returns(uint256 indexOfEra) {
        uint256 index = eraIndex[_eraName];
        require(index != 0, "No era exists with this name.");
        return index-1;
    }

    function currentEra() external view returns(bytes32 era) {
        return eras[eraLength-1];
    }

    function currentEraIndex() external view returns(uint256 indexOfEra) {
        return eraLength-1;
    }

    function eraExists(bytes32 _eraName) external view returns(bool) {
        return eraIndex[_eraName] != 0;
    }

    function totalEras() external view returns (uint256 totalEras_) {
        return eraLength;
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Minting  **************************************************/
    event Mint(
        address indexed mintContract,
        address indexed owner,
        bytes32 indexed era,
        string mokenName,
        bytes32 datahash,
        uint256 tokenId,
        bytes32 currencyName,
        uint256 price
    );

    event MintPriceChange(
        uint256 newMintPrice
    );

    uint256 public mintBasePrice = 10000 szabo;
    uint256 public mintStepPrice = 500 szabo;
    uint256 public mintPriceBuffer = 10000 szabo;


    function setMintBasePrice_(uint256 _mintBasePrice) private returns(uint256 mintPrice) {
        mintBasePrice = _mintBasePrice;
        mintPrice = _mintBasePrice + (mokensLength * mintStepPrice);
        emit MintPriceChange(mintPrice);
        return mintPrice;
    }

    function setMintBasePrice(uint256 _mintBasePrice) external onlyManager returns(uint256 mintPrice) {
        return setMintBasePrice_(_mintBasePrice);
    }

    function setMintStepPrice(uint256 _mintStepPrice) external onlyManager returns(uint256 mintPrice) {
        mintStepPrice = _mintStepPrice;
        mintPrice = mintBasePrice + (mokensLength * _mintStepPrice);
        emit MintPriceChange(mintPrice);
        return mintPrice;
    }

    function setMintPriceBuffer(uint256 _mintPriceBuffer) external onlyManager {
        mintPriceBuffer = _mintPriceBuffer;
    }

    function setMintPrice(uint256 _mintPriceBuffer, uint256 _mintBasePrice, uint256 _mintStepPrice) external onlyManager returns(uint256 mintPrice) {
        mintPriceBuffer = _mintPriceBuffer;
        mintBasePrice = _mintBasePrice;
        mintStepPrice = _mintStepPrice;
        mintPrice = _mintBasePrice + (mokensLength * _mintStepPrice);
        emit MintPriceChange(mintPrice);
        return mintPrice;
    }
    
    function mintPrice() external view returns(uint256) {
        return mintBasePrice + (mokensLength * mintStepPrice);
    }

    //moken name to tokenId
    //indexing starting at 1 instead of 0 because 0 is error condition
    //for name look ups.
    mapping (string => uint256) private tokenByName_;

    function mint(address _owner, string _mokenName, bytes32 _dataHash) external payable returns (uint256 tokenId) {

        require(_owner != address(0), "Owner cannot be the 0 address.");

        tokenId = mokensLength++;
        // prevents 32 bit overflow
        require(tokenId < MAX_MOKENS, "Only 4,294,967,296 mokens can be created.");
        uint256 mintStepPrice_ = mintStepPrice;

        //Was enough ether passed in?
        uint256 currentMintPrice = mintBasePrice + (tokenId * mintStepPrice_);
        if(msg.value < currentMintPrice) {
            require(msg.value >= (currentMintPrice - mintPriceBuffer), "Paid ether is lower than mint price.");
        }

        string memory lowerMokenName = validateAndLower(_mokenName);
        require(tokenByName_[lowerMokenName] == 0, "Moken name already exists.");

        uint256 eraIndex_ = eraLength-1;
        uint256 ownedTokensLength = ownedTokens[_owner].length;
        // prevents 16 bit overflow
        require(ownedTokensLength < MAX_OWNER_MOKENS, "An single owner address cannot possess more than 65,536 mokens.");

        // adding the current era index, ownedTokenIndex and owner address to datahash
        // this saves gas for each mint.
        uint256 dataHash = uint256(_dataHash) & MOKEN_DATA_MASK | eraIndex_ << 176 | ownedTokensLength << 160 | uint256(_owner);
        
        // create moken
        mokens[tokenId].name = _mokenName;
        mokens[tokenId].dataHash = dataHash;
        tokenByName_[lowerMokenName] = tokenId+1;

        //add moken to the specific owner
        ownedTokens[_owner].push(uint32(tokenId));

        uint256 pricePaid = currentMintPrice;
        if(msg.value < currentMintPrice) {
            pricePaid = msg.value;
        }
    
        //emit events
        emit Transfer(address(0), _owner, tokenId);
        emit Mint(this, _owner, eras[eraIndex_], _mokenName, bytes32(dataHash), tokenId, "Ether", pricePaid);
        emit MintPriceChange(currentMintPrice + mintStepPrice_);

        //send minter the change if any
        if(msg.value > currentMintPrice) {
            msg.sender.transfer(msg.value - currentMintPrice);
        }
        
        return tokenId;
    }
    
    address[] private mintContracts;
    mapping (address => uint256) private mintContractIndex;
   
   
    function addMintContract(address _contract) external onlyManager {
        require(isContract(_contract), "Address is not a contract.");
        require(mintContractIndex[_contract] == 0, "Contract already added.");
        mintContracts.push(_contract);
        mintContractIndex[_contract] = mintContracts.length;
    }
   
    function removeMintContract(address _contract) external onlyManager {
        uint256 index = mintContractIndex[_contract];
        require(index != 0, "Mint contract was not added.");
        uint256 lastIndex = mintContracts.length-1;
        address lastMintContract = mintContracts[lastIndex];
        mintContracts[index-1] = lastMintContract;
        mintContractIndex[lastMintContract] = index;
        delete mintContractIndex[_contract];
        mintContracts.length--;
    }
    
    function isMintContract(address _contract) public view returns (bool) {
        return mintContractIndex[_contract] != 0;
    }
    
    function totalMintContracts() external view returns (uint256 totalMintContracts_) {
        return mintContracts.length;
    }
    
    function mintContractByIndex(uint256 index) external view returns (address contract_) {
        require(index < mintContracts.length, "Contract index does not exist.");
        return mintContracts[index];
    }

    //Enables the ability to accept other currency/tokens from other contracts for payment in the future.
    function contractMint(address _owner, string _mokenName, bytes32 _dataHash, bytes32 _currencyName, uint256 _pricePaid) external returns (uint256 tokenId) {

        require(_owner != address(0), "Owner cannot be the 0 address.");
        require(isMintContract(msg.sender),"Not an approved mint contract.");

        tokenId = mokensLength++;
        uint256 mokensLength_ = tokenId+1;
        // prevents 32 bit overflow
        require(tokenId < MAX_MOKENS, "Only 4,294,967,296 mokens can be created.");
        
        string memory lowerMokenName = validateAndLower(_mokenName);
        require(tokenByName_[lowerMokenName] == 0, "Moken name already exists.");

        uint256 eraIndex_ = eraLength-1;
        uint256 ownedTokensLength = ownedTokens[_owner].length;
        // prevents 16 bit overflow
        require(ownedTokensLength < MAX_OWNER_MOKENS, "An single owner address cannot possess more than 65,536 mokens.");

        // adding the current era index, ownedTokenIndex and owner address to datahash
        // this saves gas for each mint.
        uint256 dataHash = uint256(_dataHash) & MOKEN_DATA_MASK | eraIndex_ << 176 | ownedTokensLength << 160 | uint256(_owner);

        // create moken
        mokens[tokenId].name = _mokenName;
        mokens[tokenId].dataHash = dataHash;
        tokenByName_[lowerMokenName] = mokensLength_;

        //add moken to the specific owner
        ownedTokens[_owner].push(uint32(tokenId));

        emit Transfer(address(0), _owner, tokenId);
        emit Mint(msg.sender, _owner, eras[eraIndex_], _mokenName, bytes32(dataHash), tokenId, _currencyName, _pricePaid);
        emit MintPriceChange(mintBasePrice + (mokensLength_ * mintStepPrice));
        
        return tokenId;
    }


    function validateAndLower(string _s) private pure returns(string mokenName) {
        bytes memory _sBytes = bytes(_s);
        uint256 length = _sBytes.length;
        require(length != 0, "Moken name cannot be an empty string.");
        require(length < 101, "Moken name cannot be greater than 100 characters.");
        //make sure the string does not start or end with whitepace.
        require(uint256(_sBytes[0]) > 0x20 && uint256(_sBytes[length-1]) > 0x20, "Moken names cannot contain leading or trailing spaces or nonprintable characters.");
        //lowercase the string
        for (uint256 i = 0; i < length; i++) {
            uint256 b = uint256(_sBytes[i]);
            if(b > 0x40) {
                if(b < 0x5b) {
                    _sBytes[i] = byte(b+32);
                }
            }
            else {
                require(b > 0x1f, "Moken names may not contain nonprintable and whitespace characters other than the space character.");
            }
        }
        return string(_sBytes);
    }

    /******************************************************************************/
    /******************************************************************************/
    /******************************************************************************/
    /* Mokens  **************************************************/

    event DataHashChange(
        uint256 indexed tokenId,
        bytes32 datahash
    );

    event DataHashPriceChange(
        uint256 price
    );

    uint256 public updateDataHashPrice_ = 0;

    function updateDataHashPrice(uint256 _updateDataHashPrice) external onlyManager {
        updateDataHashPrice_ = _updateDataHashPrice;
        emit DataHashPriceChange(_updateDataHashPrice);
    }

    // changes the dataHash of a moken
    function updateDataHash(uint256 _tokenId, bytes32 _dataHash) external onlyApproved(_tokenId) payable {
        uint256 price = updateDataHashPrice_;
        require(msg.value >= price, "Paid ether is less than the datahash update price.");
        uint256 dataHash = mokens[_tokenId].dataHash & MOKEN_HASH_MASK | uint256(_dataHash) & MOKEN_DATA_MASK;
        mokens[_tokenId].dataHash = dataHash;
        if(msg.value > price) {
            msg.sender.transfer(msg.value - price);
        }
        emit DataHashChange(_tokenId, bytes32(dataHash));
    }

    function mokenNameExists(string _mokenName) external view returns(bool) {
        return tokenByName_[validateAndLower(_mokenName)] != 0;
    }

    function mokenId(string _mokenName) external view returns (uint256 tokenId) {
        tokenId = tokenByName_[validateAndLower(_mokenName)];
        require(tokenId != 0, "No moken exists with this name.");
        return tokenId-1;
    }

    function mokenDataHash(uint256 _tokenId) external view returns (bytes32 dataHash) {
        dataHash = bytes32(mokens[_tokenId].dataHash);
        require(dataHash != 0, "The tokenId does not exist.");
        return dataHash;
    }

    function eraFromDataHash(bytes32 _dataHash) public view returns(bytes32 era) {
        return eras[uint256(_dataHash) >> 176 & UINT16_MASK];
    }

    function eraFromDataHash(uint256 _dataHash) public view returns(bytes32 era) {
        return eras[_dataHash >> 176 & UINT16_MASK];
    }

    function mokenEra(uint256 _tokenId) external view returns(bytes32 era) {
        uint256 dataHash = mokens[_tokenId].dataHash;
        require(dataHash != 0, "The tokenId does not exist.");
        return eraFromDataHash(dataHash);
    }

    function moken(uint256 _tokenId) external view 
    returns (string memory mokenName, bytes32 era, bytes32 dataHash, address owner) {
        dataHash = bytes32(mokens[_tokenId].dataHash);
        require(dataHash != 0, "The tokenId does not exist.");
        return (
            mokens[_tokenId].name, 
            eraFromDataHash(dataHash),
            dataHash, 
            address(dataHash)
        );
    }
    
    function mokenBytes32(uint256 _tokenId) external view 
    returns (bytes32 mokenNameBytes32, bytes32 era, bytes32 dataHash, address owner) {
        dataHash = bytes32(mokens[_tokenId].dataHash);
        require(dataHash != 0, "The tokenId does not exist.");
        bytes memory mokenNameBytes = bytes(mokens[_tokenId].name);
        require(mokenNameBytes.length != 0, "The tokenId does not exist.");
        assembly {
            mokenNameBytes32 := mload(add(mokenNameBytes, 32))
        }
        return (
            mokenNameBytes32, 
            eraFromDataHash(dataHash),
            dataHash, 
            address(dataHash)
        );
    }
    
    
    function mokenNoName(uint256 _tokenId) external view 
    returns (bytes32 era, bytes32 dataHash, address owner) {
        dataHash = bytes32(mokens[_tokenId].dataHash);
        require(dataHash != 0, "The tokenId does not exist.");
        return (
            eraFromDataHash(dataHash),
            dataHash, 
            address(dataHash)
        );
    }

    function mokenName(uint256 _tokenId) external view returns (string memory mokenName_) {
        mokenName_ = mokens[_tokenId].name;
        require(bytes(mokenName_).length != 0, "The tokenId does not exist.");
        return mokenName_;
    }
    
    function mokenNameBytes32(uint256 _tokenId) external view returns (bytes32 mokenNameBytes32_) {
        bytes memory mokenNameBytes = bytes(mokens[_tokenId].name);
        require(mokenNameBytes.length != 0, "The tokenId does not exist.");
        assembly {
            mokenNameBytes32_ := mload(add(mokenNameBytes, 32))
        }
        return mokenNameBytes32_;
    }
    
}


