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

    it('Prism : Listing candidate for vote ', async () => {
      const accounts = await ethers.getSigners();

      // Deployer wallet
      const user1 = accounts[0];

      //
      const candidate_1 = accounts[0];
      const candidate_2 = accounts[1];
      const candidate_3 = accounts[2];
      const candidate_4 = accounts[3];
      const candidate_5 = accounts[4];

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

      // // Prism properties
      // expect(await prism.gov()).to.equal(gov.address)
      // expect(await prism.iou()).to.equal(iou.address)

      // expect(await prism.electedLength()).to.equal(electionSize)
      // expect(await prism.electionSize()).to.equal(electionSize)
      // expect(await prism.electionVotesSize()).to.equal(electionSize)
      // expect(await prism.finalizeSize()).to.equal(electionSize)
    });

})