import { expect } from 'chai'
import { ethers } from "hardhat"

describe('Prism', () => {
  it('initializes', async () => {
    const Gov = await ethers.getContractFactory("GOV")
    const gov = await Gov.deploy()
    await gov.deployed()

    const Iou = await ethers.getContractFactory("IOU")
    const iou = await Iou.deploy()
    await iou.deployed()


    const Prism = await ethers.getContractFactory("Prism")

    const electionSize = 3
    const prism = await Prism.deploy(gov.address, iou.address, electionSize)
    await prism.deployed()

    // Prism properties
    expect(await prism.gov()).to.equal(gov.address)
    expect(await prism.iou()).to.equal(iou.address)

    expect(await prism.electedLength()).to.equal(electionSize)
    expect(await prism.electionSize()).to.equal(electionSize)
    expect(await prism.electionVotesSize()).to.equal(electionSize)
    expect(await prism.finalizeSize()).to.equal(electionSize)
  })
})