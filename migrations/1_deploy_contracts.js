const IOU = artifacts.require("IOU");
const GOV = artifacts.require("GOV");
const Prism = artifacts.require("Prism");

module.exports = async function(deployer) {
  await deployer.deploy(IOU);
  await deployer.deploy(GOV);
  await deployer.deploy(Prism, IOU.address, GOV.address, 4);
};
