const BrokenRelay = artifacts.require("./BrokenRelay.sol")
const Utils = artifacts.require("./Utils.sol")

const constants = require("./constants")
const helpers = require('./helpers');
const truffleAssert = require('truffle-assertions');

const testdata = require('./testdata/blocks.json')


var dblSha256Flip = helpers.dblSha256Flip
var flipBytes = helpers.flipBytes

// Correct functionality test cases
contract('BrokenRelay storeHeader', async(accounts) => {

    const storeGenesis = async function(){
        genesis = testdata[0]
        await relay.setInitialParent(
            genesis["header"],
            genesis["height"],
            );
    }

    beforeEach('(re)deploy contracts', async function (){ 
        relay = await BrokenRelay.new();
        utils = await Utils.deployed();
    });


    it("set Genesis as initial parent ", async () => {   
        genesis = testdata[0]
        let submitHeaderTx = await relay.setInitialParent(
            genesis["header"],
            genesis["height"]
        );
        // check if event was emmitted correctly
        truffleAssert.eventEmitted(submitHeaderTx, 'StoreHeader', (ev) => {
            return ev.blockHeight == genesis["height"];
        })

        //check header was stored correctly
        storedHeader = await relay.getBlockHeader(
            genesis["hash"]
        )
        assert.equal(storedHeader.blockHeight.toNumber(), genesis["height"])
        assert.equal(flipBytes(storedHeader.merkleRoot),  genesis["merkleroot"])
    
        //console.log("Gas used: " + submitHeaderTx.receipt.gasUsed)
    });

    it("submit 1 block after initial Genesis parent ", async () => {   
        
        storeGenesis();
        block = testdata[1]
        let submitBlock1 = await relay.submitBlockHeader(
            block["header"]
        );
        truffleAssert.eventEmitted(submitBlock1, 'StoreHeader', (ev) => {
            return ev.blockHeight == block["height"];
        });

        //console.log("Total gas used: " + submitBlock1.receipt.gasUsed);
   });


   
   it("VerifyTx with confirmations", async () => {   
    storeGenesis()
    block1 = testdata[1]    
    let submitBlock1 = await relay.submitBlockHeader(
        block1["header"]
    );
    truffleAssert.eventEmitted(submitBlock1, 'StoreHeader', (ev) => {
        return ev.blockHeight == block1["height"];
    });


    // push blocks
    confirmations = 3
    testdata.slice(2,8).forEach(b => {
        relay.submitBlockHeader(
            b["header"]
        );
    });

    tx = block1["tx"][0]
    let verifyTx = await relay.verifyTx(
        tx["tx_id"],
        block1["height"],
        tx["tx_index"],
        tx["merklePath"],
        confirmations
    )
    truffleAssert.eventEmitted(verifyTx, 'VerityTransaction', (ev) => {
        return ev.txid == tx["tx_id"];
    });
    //console.log("Total gas used: " + verifyTx.receipt.gasUsed);

    });

    it("VerifyTx large block", async () => {   
        storeGenesis()
        testdata.slice(1,3).forEach(b => {
            relay.submitBlockHeader(
                b["header"]
            );
        });   
        block = testdata[3]    

        let submitBlock = await relay.submitBlockHeader(
            block["header"]
        );
        truffleAssert.eventEmitted(submitBlock, 'StoreHeader', (ev) => {
            return ev.blockHeight == block["height"];
        });

        //truffleAssert.eventEmitted(submitBlock2, 'StoreHeader', (ev) => {
        //    return ev.blockHeight == block2["height"];
       // });
    
        confirmations = 0
    
        tx = block["tx"][0]
        let verifyTx = await relay.verifyTx(
            tx["tx_id"],
            block["height"],
            tx["tx_index"],
            tx["merklePath"],
            confirmations
        )

        truffleAssert.eventEmitted(verifyTx, 'VerityTransaction', (ev) => {
            return ev.txid == tx["tx_id"];
        });
        //console.log("Total gas used: " + verifyTx.receipt.gasUsed);
    
        });
})