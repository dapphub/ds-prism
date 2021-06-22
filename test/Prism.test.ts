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
      GOVTOken.transfer(vote_11.address, uLargeInitialBalance.toString());
      GOVTOken.transfer(vote_12.address, uMediumInitialBalance.toString());
      GOVTOken.transfer(vote_13.address, uSmallInitialBalance.toString());

      // test_etch_returns_same_id_for_same_sets
      // let candidates[3] = [];
      // console.log(candidate_1.address.toString());
      // console.log(candidate_2.address.toString());
      // console.log(candidate_3.address.toString());
      
      var candidates:string[] = [candidate_1.address.toString(), candidate_2.address.toString(), candidate_3.address.toString()]
      let electionKey = await Prism.etch(candidates);
      //console.log("KEY", electionKey.value.toString() );


      var candidates1:string[] = [candidate_5.address.toString(), candidate_6.address.toString(), candidate_3.address.toString()]
      let electionKey1 = await Prism.etch(candidates1);
      //console.log("KEY 1: ", electionKey1.value.toString() );

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
    });

})