pragma solidity ^0.4.20;

import "./SafeMath.sol";
import "./BasicToken.sol";

contract DIerToken is BasicToken {
    address public owner;
    string public name = "DIer Coin"; //自由にトークンの名前を変更可能
    string public symbol = "DC"; //トークンの単位(円とかドルみたいなもの)
    string public icon = "QmRi2y4kEnVE4zuuN8HY6KZpUAVWeZz81yN7H4rNF47fBy";
    uint public decimals = 0; //発行の最小単位。1であれば、0.1コインが最小
    uint public totalSupply = 100000; // 発行されるトークン数
    
    uint private rate = 10000; // 0.0001 ETH = 1 DC
    
    event TokenChange(address indexed from, uint256 eth_val, uint256 token_val);
    event BetResult(address indexed winner, address[] indexed looser);

    function DIerToken() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function () public payable {
        uint _tokens = msg.value.mul(rate).div(1 ether);

        //tokensが１以上で、ownerの保有コインに残りがあるかチェック
        require (_tokens > 0 && balances[owner] >= _tokens);

        //トークンの精算
        balances[owner] = balances[owner].sub(_tokens);
        balances[msg.sender] = balances[msg.sender].add(_tokens);
        Transfer(msg.sender, owner, _tokens);

        //ETHの送金
        uint _eths = _tokens.mul(1 ether).div(rate);
        owner.transfer(_eths);
        
        TokenChange(msg.sender, _eths, _tokens);
    }

    address[] public betAddress;
    mapping (address => uint256) public betTokensList;
    uint public totalBet = 0;
    uint private oneBet = 500;
    uint private executeLimit = 5;

    function betCoin() public {
        require(balances[msg.sender] >= oneBet);

        balances[msg.sender] = balances[msg.sender].sub(oneBet);
        balances[owner] = balances[owner].add(oneBet);

        totalBet += oneBet;
        betAddress.push(msg.sender);
        betTokensList[msg.sender]++;
        
        if(betAddress.length >= executeLimit) {
            address _winner = betAddress[block.timestamp % betAddress.length];
            balances[owner] = balances[owner].sub(totalBet);
            balances[_winner] = balances[_winner].add(totalBet);
            //初期化
            totalBet = 0;
            address[] memory tmp = new address[](executeLimit);
            for(uint _i = 0; _i < betAddress.length; _i++) {
                if(betAddress[_i] != _winner) {
                    tmp[_i] = betAddress[_i];
                }
                delete betTokensList[betAddress[_i]];
            }
            BetResult(_winner, tmp);
            delete betAddress;
            
        }
    }
    
    function cancelBet() public {
        uint retCoins = betTokensList[msg.sender].mul(oneBet);
        
        require(retCoins > 0 && retCoins <= totalBet);

        totalBet -= retCoins;
        
        balances[msg.sender] = balances[msg.sender].add(retCoins);
        balances[owner] = balances[owner].sub(retCoins);
        delete betTokensList[msg.sender];
        
        address[] storage tmp;
        for(uint _i = 0; _i < betAddress.length; _i++) {
            if(betAddress[_i] != msg.sender) {
                tmp.push(betAddress[_i]);
            }
        }
        betAddress = tmp;
        
    }

}