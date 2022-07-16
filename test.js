const { pkey, addr } = require("./secret.js");
const CONTRACT = require("./build/contracts/NFTToken.json");

const Caver = require("caver-js");
const rpcURL = "https://api.baobab.klaytn.net:8651/";
const caver = new Caver(rpcURL);

const temp = caver.klay.accounts.createWithAccountKey(addr, pkey);
caver.klay.accounts.wallet.add(temp);

const networkID = "1001";
const deplyedNetworkAddress = CONTRACT.networks[networkID].address;
const contract = new caver.klay.Contract(CONTRACT.abi, deplyedNetworkAddress);

async function test() {
  contract.methods
    .owner()
    .call()
    .then((res) => {
      console.log(res);
    });
}
test();
