pragma solidity ^0.4.11;

// experty token contract
contract ExpertyToken {
  function splitPartnersAllocation(address unlockedAddr, address addr, uint256 fractionEXY) public;
}

// multisignature contract, that is able to control
// ethers stored in experty token contract
contract MultisigExpertyExyControl {

  address expertyTokenAddr;

  mapping (address => bool) public isSignatory;

  mapping (uint => mapping (address => bool)) public isSigned;

  mapping(uint256 => uint8) public txSignatures;

  uint8 requiredSignatures;

  struct Tx {
    address unlockedAddr;
    address addr;
    uint256 fractionEXY;
    address creator;
    bool rejected;
    bool executed;
    uint8 signatures;
  }
  Tx[] public txs;

  // 4 from 6 multisig wallet
  function MultisigExpertyExyControl() public {
    // 3 signatories from Experty:
    isSignatory[0xe115c9788615511736F88c0DBB7282569611a338] = true;
    isSignatory[0x0B0371682DAA1aBEC52B39b65d66BEA5CbEE84aC] = true;
    isSignatory[0x5059C45264E6Cba7D8D805Cf5Cc54A881CF0DB73] = true;

    // set required signatures
    requiredSignatures = 2;
  }

  // set experty token address after deploying experty token contract
  function setExpertyTokenAddr(address addr) public onlySignatory {
    // experty token address can be set only once after deploy;
    require(expertyTokenAddr == 0x0);
    expertyTokenAddr = addr;
  }

  // propose tx transaction from experty token contract
  function proposeTx(address unlockedAddr, address addr, uint256 fractionEXY) public onlySignatory {
    txs.push(Tx({
      unlockedAddr: unlockedAddr,
      addr: addr,
      fractionEXY: fractionEXY,
      creator: msg.sender,
      rejected: false,
      executed: false,
      signatures: 0
    }));
  }

  // reject proposed transaction
  function rejectTx(uint txIdx) public onlySignatory {
    // only creator of transaction can reject it
    require(txs[txIdx].creator == msg.sender);
    // reject only not executed transactions
    require(!txs[txIdx].executed);
    txs[txIdx].rejected = true;
  }

  // sign specified transaction
  function signTx(uint txIdx) public onlySignatory {
    // transaction can be signed once by any participant
    require(!isSigned[txIdx][msg.sender]);

    isSigned[txIdx][msg.sender] = true;
    txs[txIdx].signatures += 1;

    txCallAttemp(txIdx);
  }

  // try to call tx function
  function txCallAttemp(uint txIdx) public {
    // check if there is enough number of signatures
    require(requiredSignatures <= txs[txIdx].signatures);

    ExpertyToken experty = ExpertyToken(expertyTokenAddr);
    experty.splitPartnersAllocation(txs[txIdx].unlockedAddr, txs[txIdx].addr, txs[txIdx].fractionEXY);
  }

  // only signatory can call this
  modifier onlySignatory() {
    require(isSignatory[msg.sender]);
    // make sure, that it is direct call of the function
    // and it is not called by any contract
    require(msg.sender == tx.origin);
    _;
  }
}
