const { expect } = require("chai");
const { ethers } = require("hardhat");
//loads expect object from chai
const Web3Utils = require('web3-utils');
// Connect to the Test RPC running
const Web3 = require('web3');
const web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));
if(web3.isConnected()) {
    console.log("connected"); 
    } else {
    console.log("not connected")
    }
    const blockNumber = await web3.eth.getBlockNumber();
    const blockHash = await web3.eth.getBlock(await web3.eth.getBlockNumber()).hash;
                       
    const timestamp = await web3.eth.getBlock(await web3.eth.getBlockNumber()).timestamp;
    

describe("MyContract", function () {
    let Contract;
    let myContract;
    let owner;
    let validator1;
    let validator2;
    let nonValidator;

    beforeEach(async function () {
        // Get the ContractFactory and Signers here.
        Contract = await ethers.getContractFactory("MyContract");
        [owner, validator1, validator2, nonValidator] = await ethers.getSigners();

        // To deploy our contract, we just have to call Token.deploy() and await
        // for it to be deployed(), which happens once its transaction has been
        // mined.
        myContract = await Contract.deploy([validator1.address, validator2.address]);
    });

    describe('Deployment', function () {
        it("should initilize them as validators", async () => {
            //checks if verified validator is registered as one
            const isValidator1Bool = await myContract.isValidator(validator1.address);
            expect(isValidator1Bool).to.equal(true);

            const isValidator2Bool = await myContract.isValidator(validator2.address);
            expect(isValidator2Bool).to.equal(true);

        })
        it("should not initilize them as validators", async () => {
            //checks if NON-verefied address is registered as validator(owner and random address)
            const isOwnerBool = await myContract.isValidator(owner.address);
            expect(isOwnerBool).to.equal(false);

            const nonValidatorBool = await myContract.isValidator(nonValidator.address);
            expect(nonValidatorBool).to.equal(false);
        })

        const block = web3.eth.getBlock(1);
        const TESTCHAINID = "0x1111111111111111111111111111111111111111111111111111111111111111";
        const blockHash = "0xf9025c44441555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347940000000000000000000000000000000000000000a0f526f481ffb6c3c56956d596f2b23e1f7ff17c810ba59efb579d9334a1765444a007f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586a0907121bec78b40e8256fac47867d955c560b321e93fc9f046f919ffb5e3823ffb90100224400000200000900000000000000000410000800000080000880000800000002000004000008000000000000004000000000000000000000100000080201020000000000000800000000088000000000000220000000040000000100000000000800000006204004401000102004000820000000000000800400100001000200200000000000000800800000010000000001000004004800000000020000000020000800180000081080001000000000000000000200000500100010040000000001020000400040000000000000000000000044000000000000000000000002080000000004000082000200000040224000000000040002008480000000000283288c8e837295a1832bffa2845b4f6b1db861d68301080d846765746886676f312e3130856c696e7578000000000000000000583a78dd245604e57368cb2688e42816ebc86eff73ee219dd96b8a56ea6392f75507e703203bc2cc624ce6820987cf9e8324dd1f9f67575502fe6060d723d0e100a00000000000000000000000000000000000000000000000000000000000000000880000000000000000";

        const TESTBLOCKHEADER = {
            parentHash: '0x3471444ab9a99528f02f94448f0017fe2f56e01116acc4fe7f78aee900442f35',
            timestamp: 1534441421,
            number: 2654442,
            author: 0x3444455ab9a99528f02f9cdd8f0017fe2f56e01116,
            transactions_root: '0x1dcc4de844475d7aab85b567b644441ad312451b948a7413f0a142fd40d49347',
            uncles_hash: '0x1dcc4de8dec75d7a4445b567b6ccd41ad3124444948a7413f0a142fd40d49347',
            extra_data: '3428944489fhd9',
            state_root: '0xf526f481ff444c56956d596f2b23e1f7ff17c814449efb579d9334a1765444',
            receipts_root: '0x0000000000000000',
            log_bloom: '0x22440000044400090000000000000000041000080000008000088000080000000200000400000800000000000000400000000000000000000010000008020102000000000000080000000008800000000000022000000004000000010000000000080000000620400440100010200400082000000000000080040010000100020020000000000000080080000001000000000100000400480000000002000000002000080018000008108000100000000000000000020000050010001004000000000102000040004000000000000000000000004400000000000000000000000208000000000400008200020000004022400000000004000200848000000000',
            gas_used: 4443490,
            gas_limit:7504449,
            difficulty:5024446,
            mixHash:'0x0000000000000000000000000000000000000000000000000000000000000000',
            nonce:'0x0000000000000000'
        }

        it("Should add blockhash to verified block hashes", async function () {
            await myContract.connect(validator1).addSignedBlock(TESTBLOCKHEADER,TESTCHAINID,validator1.getSignature,blockHash)
        });
        
    });
});

