// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract MyContract {
    string private name;
    mapping(bytes32 => BlockData) private blockhashBlockDataMapping;
    mapping(bytes32 => SignedBlock) private blockhashSignedBlockMapping;
    mapping(address => bool) private trustedValidator;
    mapping(bytes32 => bool) private submittedBlocks;

    mapping(address => bool) private blockHashInitilized;

    struct BlockHeader {
        bytes32 parent_hash;
        uint256 timestamp;
        uint256 number;
        address author;
        bytes32 transactions_root;
        bytes32 uncles_hash;
        bytes extra_data;
        bytes32 state_root;
        bytes32 receipts_root;
        bytes log_bloom;
        uint256 gas_used;
        uint256 gas_limit;
        uint256 difficulty;
        bytes32 mixHash;
        uint256 nonce;
    }

    struct BlockData {
        BlockHeader header;
        bytes rlpHeader;
        bytes32 blockHash;
    }

    struct SignedBlock {
        bytes[] signatures;
        mapping(address => bool) hasValidatorSigned;
        //to prevent double signatures
    }

    modifier onlyValidator() {
        require(
            trustedValidator[msg.sender],
            "Only trusted Validators can call this function."
        );
        _;
    }

    constructor(address[] memory trustedValidatorsArr) {
        for (uint256 i = 0; i < trustedValidatorsArr.length; i++) {
            trustedValidator[trustedValidatorsArr[i]] = true;
        }
    }

    function addSignedBlock(
        uint256 _blockchainid,
        BlockHeader memory blockheader,
        bytes32 _blockhash,
        bytes memory signature
    ) public onlyValidator {
        require(!submittedBlocks[_blockhash], "block has been added already");
        require(!blockHashInitilized[msg.sender], "Validator already added this block.");

        require(
            verifySignature(_blockchainid, blockheader, signature, _blockhash),
            "blockhash and blockheader with signiture dose not match."
        );
        require(
            blockhashSignedBlockMapping[_blockhash].hasValidatorSigned[msg.sender],
            "Validator already signed this block."
        );

        // if were here all requirments are answered
        BlockData memory currBlock = BlockData(
            blockheader,
            signature,
            _blockhash
        );
        blockhashBlockDataMapping[_blockhash] = currBlock;
        blockhashSignedBlockMapping[_blockhash].hasValidatorSigned[msg.sender] = true;

        blockHashInitilized[msg.sender] = true;
    }


    function isValidator(address candidateAdress) public view returns (bool) {
        return trustedValidator[candidateAdress];
    }

    function verifySignature(
        uint256 _blockchainid,
        BlockHeader memory blockheader,
        bytes memory signature,
        bytes32 _blockhash
    ) private view returns (bool) {
        bytes32 blockHeaderHash = getBlockHeaderHash(
            _blockchainid,
            blockheader);

        bytes32 _ethSignedblockHeaterHash = getEthSignedBlockHeaderHash(
            blockHeaderHash);

        return (recoverSigner(_ethSignedblockHeaterHash, signature) == msg.sender) && (blockHeaderHash == _blockhash);
          
    }

    function recoverSigner(
        bytes32 _ethSignedblockHeaterHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedblockHeaterHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (r, s, v);
    }

    function getBlockHeaderHash(
        uint256 _blockchainid,
        BlockHeader memory blockheader
    ) private pure returns (bytes32) {
        //to prevent stack too deep compilation error split into 3 hash's and have a mini merkle tree;
        bytes32 firstHash = keccak256(
            abi.encodePacked(
                _blockchainid,
                blockheader.parent_hash,
                blockheader.timestamp,
                blockheader.number,
                blockheader.author,
                blockheader.transactions_root,
                blockheader.uncles_hash,
                blockheader.extra_data
            )
        );
        bytes32 secondHash = keccak256(
            abi.encodePacked(
                blockheader.state_root,
                blockheader.receipts_root,
                blockheader.log_bloom,
                blockheader.gas_used,
                blockheader.gas_limit
            )
        );
        return (
            keccak256(
                abi.encodePacked(
                    firstHash,
                    secondHash,
                    blockheader.difficulty,
                    blockheader.mixHash,
                    blockheader.nonce
                )
            )
        );
    }

    function getEthSignedBlockHeaderHash(bytes32 _blockHeaderHash)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _blockHeaderHash
                )
            );
    }
}
