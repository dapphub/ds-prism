import { expect } from 'chai'
import { ethers } from "hardhat"

describe('Prism', () => {

    it('initializes : Token contractsi ( IOU, GOV )', async () => {

      const accounts = await ethers.getSigners();

      const user1 = accounts[0];

      const GOVModel = await ethers.getContractFactory("ERC20Token")
      const GOVTOken = await GOVModel.deploy("GOV","GOV")
      await GOVTOken.deployed();
      
      expect(await GOVTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

      const IOUModel = await ethers.getContractFactory("ERC20Token")
      const IOUTOken = await IOUModel.deploy("IOU","IOU")
      await IOUTOken.deployed()

      expect(await IOUTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

    })

    it('initializes : Prism contract ', async () => {
      const accounts = await ethers.getSigners();

      const user1 = accounts[0];

      const GOVModel = await ethers.getContractFactory("ERC20Token")
      const GOVTOken = await GOVModel.deploy("GOV","GOV")
      await GOVTOken.deployed();
      
      expect(await GOVTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

      const IOUModel = await ethers.getContractFactory("ERC20Token")
      const IOUTOken = await IOUModel.deploy("IOU","IOU")
      await IOUTOken.deployed()

      expect(await IOUTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

      const PrismModel = await ethers.getContractFactory("Prism")
      const electionSize = 3
      const Prism = await PrismModel.deploy(GOVTOken.address, IOUTOken.address, electionSize)
      await Prism.deployed()

      expect(await Prism.gov()).to.equal(GOVTOken.address)
      expect(await Prism.iou()).to.equal(IOUTOken.address)

    });

    it('Prism : Governance token disribution to voters', async () => {
      const accounts = await ethers.getSigners();

      // Deployer wallet ( default wallet )
      const user1 = accounts[0];

      const GOVModel = await ethers.getContractFactory("ERC20Token")
      const GOVTOken = await GOVModel.deploy("GOV","GOV")
      await GOVTOken.deployed();
      
      expect(await GOVTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

      // Initial Balance
      let initialBalance = await ethers.utils.parseEther("1000");
      
      let uLargeInitialBalance = Number(initialBalance) / 3;
      let uMediumInitialBalance = Number(initialBalance) / 4;
      let uSmallInitialBalance = Number(initialBalance) / 5;

      // PrismUser
      // <!-- Voter -->
      const voter_11 = accounts[11]; 
      const voter_12 = accounts[12];
      const voter_13 = accounts[13];

      //
      // <!-- Transfer Governance token --> 
      GOVTOken.transfer(voter_11.address, uLargeInitialBalance.toString());
      GOVTOken.transfer(voter_12.address, uMediumInitialBalance.toString());
      GOVTOken.transfer(voter_13.address, uSmallInitialBalance.toString());

    });

    it('Prism : Checking etch returns same id for same sets', async () => {
      const accounts = await ethers.getSigners();

      // Deployer wallet ( default wallet )
      const user1 = accounts[0];

      const GOVModel = await ethers.getContractFactory("ERC20Token")
      const GOVTOken = await GOVModel.deploy("GOV","GOV")
      await GOVTOken.deployed();
      
      expect(await GOVTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

      const IOUModel = await ethers.getContractFactory("ERC20Token")
      const IOUTOken = await IOUModel.deploy("IOU","IOU")
      await IOUTOken.deployed()

      expect(await IOUTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")
      
      const PrismModel = await ethers.getContractFactory("Prism")
      const electionSize = 3
      const Prism = await PrismModel.deploy(GOVTOken.address, IOUTOken.address, electionSize)
      await Prism.deployed()

      expect(await Prism.gov()).to.equal(GOVTOken.address)
      expect(await Prism.iou()).to.equal(IOUTOken.address)

      await IOUTOken.transfer(Prism.address, "10000000000000000000000")
      expect(await IOUTOken.balanceOf(Prism.address)).to.equal("10000000000000000000000")

      //
      // <!-- Candidate --> 
      const candidate_1 = accounts[1];
      const candidate_2 = accounts[2];
      const candidate_3 = accounts[3];

      // Initial Balance
      let initialBalance = await ethers.utils.parseEther("1000");
      
      let uLargeInitialBalance = Number(initialBalance) / 3;
      let uMediumInitialBalance = Number(initialBalance) / 4;
      let uSmallInitialBalance = Number(initialBalance) / 5;

      // PrismUser
      // <!-- Voter -->
      const vote_11 = accounts[11]; 
      const vote_12 = accounts[12];
      const vote_13 = accounts[13];

      //
      // <!-- Transfer Governance token --> 
      await GOVTOken.transfer(vote_11.address, uLargeInitialBalance.toString());
      await GOVTOken.transfer(vote_12.address, uMediumInitialBalance.toString());
      await GOVTOken.transfer(vote_13.address, uSmallInitialBalance.toString());

      expect(await Prism.electionInc()).to.equal("0")

      var candidates:string[] = [candidate_1.address.toString(), candidate_2.address.toString(), candidate_3.address.toString()]
      let electionKey = await Prism.etch(candidates);
    
      //   
      expect(await Prism.electionInc()).to.equal("1")

    });

    it('Prism : user by user trying voting to list of candidates, trying vot through GOV token, and receive IOU token from smart contracts', async () => {
      const accounts = await ethers.getSigners();

      // Deployer wallet ( default wallet )
      const user1 = accounts[0];

      const GOVModel = await ethers.getContractFactory("ERC20Token")
      const GOVTOken = await GOVModel.deploy("GOV","GOV")
      await GOVTOken.deployed();
      
      expect(await GOVTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")

      const IOUModel = await ethers.getContractFactory("ERC20Token")
      const IOUTOken = await IOUModel.deploy("IOU","IOU")
      await IOUTOken.deployed()

      expect(await IOUTOken.balanceOf(user1.address)).to.equal("10000000000000000000000000")
      
      const PrismModel = await ethers.getContractFactory("Prism")
      const electionSize = 3
      const Prism = await PrismModel.deploy(GOVTOken.address, IOUTOken.address, electionSize)
      await Prism.deployed()

      expect(await Prism.gov()).to.equal(GOVTOken.address)
      expect(await Prism.iou()).to.equal(IOUTOken.address)

      await IOUTOken.transfer(Prism.address, "10000000000000000000000000")
      expect(await IOUTOken.balanceOf(Prism.address)).to.equal("10000000000000000000000000")

      //
      // <!-- Candidate --> 
      const candidate_1 = accounts[1];
      const candidate_2 = accounts[2];
      const candidate_3 = accounts[3];
      const candidate_4 = accounts[4];
      const candidate_5 = accounts[5];
      const candidate_6 = accounts[6];
      const candidate_7 = accounts[7];
      const candidate_8 = accounts[8];
      const candidate_9 = accounts[9];
      const candidate_10 = accounts[10];

      // Initial Balance
      let initialBalance = await ethers.utils.parseEther("1000");
      
      let uLargeInitialBalance = Number(initialBalance) / 3;
      let uMediumInitialBalance = Number(initialBalance) / 4;
      let uSmallInitialBalance = Number(initialBalance) / 5;

      // PrismUser
      // <!-- Voter -->
      const vote_11 = accounts[11]; 
      const vote_12 = accounts[12];
      const vote_13 = accounts[13];

      //
      // <!-- Transfer Governance token --> 
      await GOVTOken.transfer(vote_11.address, uLargeInitialBalance.toString());
      await GOVTOken.transfer(vote_12.address, uMediumInitialBalance.toString());
      await GOVTOken.transfer(vote_13.address, uSmallInitialBalance.toString());

      expect(await Prism.electionInc()).to.equal("0")

      var candidates:string[] = [candidate_1.address.toString(), candidate_2.address.toString(), candidate_3.address.toString()]
      let electionKey = await Prism.etch(candidates);
    
      //   
      expect(await Prism.electionInc()).to.equal("1")


      // var candidates1:string[] = [candidate_5.address.toString(), candidate_6.address.toString(), candidate_3.address.toString()]
      // let electionKey1 = await Prism.etch(candidates1);
      // console.log("KEY 1: ", electionKey1.value.toString('hex') );

      //assert(id != 0x0);      //

      // DSPrism prism;
      // DSToken GOV;
      // DSToken IOU;

      // // u prefix: user
      // PrismUser uLarge;
      // PrismUser uMedium;
      // PrismUser uSmall;

      // // Prism properties
      // expect(await prism.gov()).to.equal(gov.address)
      // expect(await prism.iou()).to.equal(iou.address)

      // expect(await prism.electedLength()).to.equal(electionSize)
      // expect(await prism.electionSize()).to.equal(electionSize)
      // expect(await prism.electionVotesSize()).to.equal(electionSize)
      // expect(await prism.finalizeSize()).to.equal(electionSize)

      //
      
      
      // CONTRACT INITIALIZATION
      // <!----- USER 1 ---->
      let GOVTokenVoter11 = await GOVTOken.connect(vote_11);
      let PrismVoter11    = await Prism.connect(vote_11);

      expect(await GOVTokenVoter11.balanceOf(vote_11.address)).to.equal(uLargeInitialBalance.toString());

      let lockedAmt = Number(uLargeInitialBalance) / 3;
      //let lockedAmt = 10;

      //console.log("SENDER : ", lockedAmt);
      await GOVTokenVoter11.approve(Prism.address, lockedAmt.toString());

      await PrismVoter11.lock(lockedAmt.toString());

      await PrismVoter11.vote(lockedAmt.toString());
      
      await PrismVoter11.vote("0");                      // <!--- Voter 1 voting on Election -> 0

      // <!----- USER 2 ---->
      let GOVTokenVoter22 = await GOVTOken.connect(vote_12);
      let PrismVoter22    = await Prism.connect(vote_12);

      expect(await GOVTokenVoter22.balanceOf(vote_12.address)).to.equal(uMediumInitialBalance.toString());

      let lockedAmt2 = Number(uMediumInitialBalance) / 4;
      //let lockedAmt = 10;

      await GOVTokenVoter22.approve(Prism.address, lockedAmt2.toString());

      await PrismVoter22.lock(lockedAmt2.toString());

      await PrismVoter11.vote("0");                      // <!--- Voter 2 voting on Election -> 0

    });

})