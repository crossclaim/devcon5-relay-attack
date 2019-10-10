pragma solidity >=0.4.22 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Utils.sol";

/// @title Broken BTC Relay contract. FIX ME!!!
/// @notice For simplicity, this example assumes:
/// (i) constant difficulty
/// (ii) no forks occur
contract BrokenRelay {
    using SafeMath for uint256;
    using Utils for bytes;
    using Utils for bytes32;

    struct Header {
        uint256 blockHeight; // height of this block header
        bytes32 merkleRoot; // transaction Merkle tree root
    }

    // mapping of block hashes to block headers (ALL ever submitted, i.e., incl. forks)
    mapping(bytes32 => Header) public _headers;

    // mapping of block heights to block hashes of the MAIN CHAIN
    mapping(uint256 => bytes32) public _mainChain;

    // block with the most accumulated work, i.e., blockchain tip
    bytes32 public _heaviestBlock;
    uint256 public _heaviestHeight;

    // CONSTANTS
    /*
    * Bitcoin difficulty constants
    */
    uint256 public constant DIFFICULTY_ADJUSTMENT_INVETVAL = 2016;
    uint256 public constant DIFF_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;
    uint256 public constant TARGET_TIMESPAN = 14 * 24 * 60 * 60; // 2 weeks
    uint256 public constant UNROUNDED_MAX_TARGET = 2**224 - 1;
    uint256 public constant TARGET_TIMESPAN_DIV_4 = TARGET_TIMESPAN / 4; // store division as constant to save costs
    uint256 public constant TARGET_TIMESPAN_MUL_4 = TARGET_TIMESPAN * 4; // store multiplucation as constant to save costs


    // EVENTS
    /*
    * @param blockHash block header hash of block header submitted for storage
    * @param blockHeight blockHeight
    */
    event StoreHeader(bytes32 indexed blockHash, uint256 indexed blockHeight);
    /*
    * @param txid block header hash of block header submitted for storage
    */
    event VerityTransaction(bytes32 indexed txid, uint256 indexed blockHeight);

    // EXCEPTION MESSAGES
    // TODO: Use these error messages for the testcases!
    string ERR_GENESIS_ALREADY_SET = "Initial parent has already been set";
    string ERR_INVALID_HEADER_FORMAT = "Invalid block header";
    string ERR_DUPLICATE_BLOCK_SUBMISSION = "Block already stored";
    string ERR_PREV_BLOCK_NOT_FOUND = "Previous block hash not found";
    string ERR_DIFF_TARGET_HEADER = "PoW hash does not meet difficulty target of header";
    string ERR_INVALID_TXID = "Invalid transaction identifier";
    string ERR_CONFIRMS = "Transaction has less confirmations than requested";
    string ERR_MERKLE_PROOF = "Invalid Merkle Proof structure";
    string ERR_VERIFY_TX = "Incorrect Merkle Proof!";

    string ERR_NOT_MAIN_CHAIN = "Main chain submission indicated, but submitted block is on a fork";
    string ERR_BLOCK_NOT_FOUND = "Requested block not found in storage";


    /**
    * @notice Initializes the relay with the provided block, i.e., defines the first block of the stored chain
    * @param blockHeaderBytes - 80 bytes raw Bitcoin block headers
    * @param blockHeight - blockHeight of genesis block
    */
    function setInitialParent(
        bytes memory blockHeaderBytes,
        uint32 blockHeight
        )
        public
        {
        // TESTCASE 1: Do we allow users to reset the relay with a new genesis block at will??
        // TODO: add check! 

        bytes32 blockHeaderHash = blockHashFromHeader(blockHeaderBytes);
        _heaviestBlock = blockHeaderHash;
        _heaviestHeight = blockHeight;
        _headers[blockHeaderHash].merkleRoot = getMerkleRootFromHeader(blockHeaderBytes);
        _headers[blockHeaderHash].blockHeight = blockHeight;
        emit StoreHeader(blockHeaderHash, blockHeight);
    }


    /**
    * @notice Parses, validates and stores Bitcoin block header1 to mapping
    * @param blockHeaderBytes Raw Bitcoin block header bytes (80 bytes)
    * @return bytes32 Bitcoin-like double sha256 hash of submitted block
    */
    function submitBlockHeader(bytes memory blockHeaderBytes) public returns (bytes32) {
        
        // TESTCASE 3a, 3b: block header is provided by the user. What could go wrong???
        // TODO: add check!

        // Extract prev and cacl. current block header hashes
        bytes32 hashPrevBlock = getPrevBlockHashFromHeader(blockHeaderBytes);
        bytes32 hashCurrentBlock = blockHashFromHeader(blockHeaderBytes);

        // TESTCASE 2: Maybe we should not allow duplicate submissions?
        // TODO: add check!
        // Note: merkleRoot field is always set if a block is stored
    
        // TESTCASE 4: Shall we make sure we are building a chain and not storing random blocks?
        // TODO: add check!
        // Note: merkleRoot field is always set if a block is stored

        uint256 target = getTargetFromHeader(blockHeaderBytes);

        // TESTCASE 5: Did the miner do the work?
        // TODO: check!

        // NOTE: for simplicity, we do not check retargetting here.
        // That is, we assume constant difficulty in this example!
        // A fully functional relay must check retarget!

        // Calc. blockheight
        uint256 blockHeight = 1 + _headers[hashPrevBlock].blockHeight;

        // Check that the submitted block is extending the main chain
        require(blockHeight > _heaviestHeight, ERR_NOT_MAIN_CHAIN);

        // Update stored heaviest block and height
        _heaviestBlock = hashCurrentBlock;
        _heaviestHeight = blockHeight;

        // Write block header to storage
        bytes32 merkleRoot = getMerkleRootFromHeader(blockHeaderBytes);
        _headers[hashCurrentBlock].merkleRoot = merkleRoot;
        _headers[hashCurrentBlock].blockHeight = blockHeight;

        // Update main chain reference
        _mainChain[blockHeight] = hashCurrentBlock;

        emit StoreHeader(hashCurrentBlock, blockHeight);
    }

    /**
    * @notice Verifies that a transaction is included in a block at a given blockheight
    * @param txid transaction identifier
    * @param txBlockHeight block height at which transacton is supposedly included
    * @param txIndex index of transaction in the block's tx merkle tree
    * @param merkleProof  merkle tree path (concatenated LE sha256 hashes)
    * @return True if txid is at the claimed position in the block at the given blockheight, False otherwise
    */
    function verifyTx(
        bytes32 txid,
        uint256 txBlockHeight,
        uint256 txIndex,
        bytes32[] memory merkleProof,
        uint256 confirmations)
        public returns(bool)
        {
        // TESTCASE 6:  txid is provided by the user. What could go wrong?
        // TODO: add check!

        // TESTCASE 7: What must the first hash of the Merkle path be?
        // How can we be sure we are verifying the proof for the correct transaction?
        // TODO: add check!
        // Note: use XXX.flip32Bytes() to convert between BRE and LE!
        
        // TESTCASE 8: Are we sure this transaction is "securely" included?
        // TODO: add check!

        bytes32 blockHeaderHash = _mainChain[txBlockHeight];
        bytes32 merkleRoot = _headers[blockHeaderHash].merkleRoot;
        
        // Compute merkle tree root and check if it matches the specified block's merkle tree root
        bytes32 calcRoot = computeMerkle(txIndex, merkleProof);

        require(calcRoot == merkleRoot, ERR_VERIFY_TX);

        emit VerityTransaction(txid, txBlockHeight);

        return true;
    }


    // HELPER FUNCTIONS
    /**
    * @notice Reconstructs merkle tree root given a transaction hash, index in block and merkle tree path
    * @param txIndex index of transaction given by hash in the corresponding block's merkle tree
    * @param merkleProof merkle tree path to transaction hash from block's merkle tree root
    * @return merkle tree root of the block containing the transaction, meaningless hash otherwise
    */
    function computeMerkle(
        uint256 txIndex,
        bytes32[] memory merkleProof)
        public pure returns(bytes32)
        {

        bytes32 resultHash = merkleProof[0];
        uint256 txIndexTemp = txIndex;
        
        for(uint i = 1; i < merkleProof.length; i++) {
            if(txIndexTemp % 2 == 1){
                resultHash = concatSHA256Hash(merkleProof[i], resultHash);
            } else {
                resultHash = concatSHA256Hash(resultHash, merkleProof[i]);
            }
            txIndexTemp.div(2);
        }
        return resultHash;
    }
    
    /**
    * @notice Computes the Bitcoin double sha256 block hash for a given block header
    */
    function blockHashFromHeader(bytes memory blockHeaderBytes) public pure returns (bytes32){
        return dblSha(blockHeaderBytes).flipBytes().toBytes32();
    }
    /** 
    * @notice Concatenates and re-hashes two SHA256 hashes
    * @param left left side of the concatenation
    * @param right right side of the concatenation
    * @return sha256 hash of the concatenation of left and right
    */
    function concatSHA256Hash(bytes32 left, bytes32 right) public pure returns (bytes32) {
        return dblSha(abi.encodePacked(left).concat(abi.encodePacked(right))).toBytes32();
    }
    /**
    * @notice Performs Bitcoin-like double sha256 hash calculation
    * @param data Bytes to be flipped and double hashed s
    * @return Bitcoin-like double sha256 hash of parsed data
    */
    function dblSha(bytes memory data) public pure returns (bytes memory){
        return abi.encodePacked(sha256(abi.encodePacked(sha256(data))));
    }

    /**
    * @notice Calculates the PoW difficulty target from compressed nBits representation,
    * according to https://bitcoin.org/en/developer-reference#target-nbits
    * @param nBits Compressed PoW target representation
    * @return PoW difficulty target computed from nBits
    */
    function nBitsToTarget(uint256 nBits) private pure returns (uint256){
        uint256 exp = uint256(nBits) >> 24;
        uint256 c = uint256(nBits) & 0xffffff;
        uint256 target = uint256((c * 2**(8*(exp - 3))));
        return target;
    }

    // GETTERS
    function getMerkleRootFromHeader(bytes memory blockHeaderBytes) public pure returns(bytes32){
        return blockHeaderBytes.slice(36,32).toBytes32();
    }

    function getTargetFromHeader(bytes memory blockHeaderBytes) public pure returns(uint256){
        return nBitsToTarget(getNBitsFromHeader(blockHeaderBytes));
    }
    
    function getNBitsFromHeader(bytes memory blockHeaderBytes) public pure returns(uint256){
        return blockHeaderBytes.slice(72, 4).flipBytes().bytesToUint();
    }
    
    function getPrevBlockHashFromHeader(bytes memory blockHeaderBytes) public pure returns(bytes32){
        return blockHeaderBytes.slice(4, 32).flipBytes().toBytes32();
    }
    // https://en.bitcoin.it/wiki/Difficulty
    function getDifficulty(uint256 target) public pure returns(uint256){
        return DIFF_TARGET.div(target);
    }

    function getBlockHeader(bytes32 blockHeaderHash) public view returns(
        uint256 blockHeight,
        bytes32 merkleRoot
    ){
        require(_headers[blockHeaderHash].merkleRoot != bytes32(0x0), ERR_BLOCK_NOT_FOUND);
        blockHeight = _headers[blockHeaderHash].blockHeight;
        merkleRoot = _headers[blockHeaderHash].merkleRoot;
        return(blockHeight, merkleRoot);
    }
}
