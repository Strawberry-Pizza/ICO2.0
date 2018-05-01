token_addr = "0x129eu1202h3r90hf2309f2f23f"
teamWallet_addr = ""
members_addr = []

var Fund = artifacts.require("./Fund.sol");

contract('Fund', async (token_addr, teamWallet_addr, members_addr) => {
    //Function test
    it("construct Fund", async () => {
        let fund = await Fund.deployed(token_addr, teamWallet_addr, members_addr);
        assert.equal(fund.state, FUNDSTATE.BEFORE_SALE, "not created Fund.");
    });

})

