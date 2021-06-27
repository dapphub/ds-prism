const IOU = artifacts.require("ERC20Token");
const GOV = artifacts.require("ERC20Token");
const Prism = artifacts.require("Prism");

module.exports = async function(deployer) {
  await deployer.deploy(IOU, "IOU", "IOU");
  await deployer.deploy(GOV, "GOV", "GOV");
  await deployer.deploy(Prism, IOU.address, GOV.address, 4);
};
