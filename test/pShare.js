const ProfitShare = artifacts.require('./ProfitShare.sol');
//const contract = require('truffle-contract'); 

const toWei = (number) => number * Math.pow(10, 18);
// various test utility functions
const transaction = (address, wei) => ({
  from: address,
  value: wei
});

const ethBalance = (address) => web3.eth.getBalance(address).toNumber();

contract('ProfitShare', accounts => {

  const admin1 = accounts[1];
  const admin2 = accounts[2];
  const admin3 = accounts[3];

  const admin4 = accounts[4];  

  const contractAddress = accounts[4];

  const oneEth = toWei(1);

  const createPool = () => ProfitShare.new(admin4);

  it('check addresses', async () => {
    const pool = await createPool();

    pool.adminAddWhiteList(admin1, {from: admin4});
    pool.adminAddWhiteList(admin2, {from: admin4});
    pool.adminAddWhiteList(admin3, {from: admin4});

    await pool.sendTransaction(transaction(admin1, oneEth));
    await pool.sendTransaction(transaction(admin2, oneEth));

    var user = await pool.getUser(0);
    assert.equal(user, admin1, 'getUser(0) error');

    var user = await pool.getUser(1);
    assert.equal(user, admin2, 'getUser(1) error');

    await pool.sendTransaction(transaction(admin2, oneEth));
    await pool.sendTransaction(transaction(admin3, oneEth));
    var user = await pool.getUser(2);
    assert.equal(user, admin3, 'getUser(2) error');

    var current1 = ethBalance(admin1);
    var current2 = ethBalance(admin2);

    //await pool.sendTransaction(transaction(admin4, toWei(4)));

    //assert.equal(ethBalance(admin1), oneEth+current1);
    //assert.equal(ethBalance(admin2), oneEth+current2+oneEth);

    var ret = await pool.adminUpdateBlackList(admin3, true, {from:admin4});
    //console.log(ret);
    //assert.equal(ret, true);
    await pool.sendTransaction(transaction(admin4, toWei(4)));

  });

});

