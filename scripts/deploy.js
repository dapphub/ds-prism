// <!-- main function -->
async function main() {
    // // We get the contract to deploy
    // const Greeter = await ethers.getContractFactory("Greeter");
    // const greeter = await Greeter.deploy("Hello, Hardhat!");
  
    // console.log("Greeter deployed to:", greeter.address);



    const GOVModel = await ethers.getContractFactory("ERC20Token");
    const GOVTOken = await GOVModel.deploy("GOV","GOV");
    await GOVTOken.deployed();

    const IOUModel = await ethers.getContractFactory("ERC20Token");
    const IOUTOken = await IOUModel.deploy("IOU","IOU");
    await IOUTOken.deployed()
    
    const PrismModel = await ethers.getContractFactory("Prism");
    const electionSize = 3;
    const Prism = await PrismModel.deploy(GOVTOken.address, IOUTOken.address, electionSize);
    await Prism.deployed();

    console.log(`
        GOV Token contract address      :   ${GOVTOken.address} \n
        IOU Token contract address      :   ${IOUTOken.address} \n
        Prism Token contract address    :   ${Prism.address}    \n
    `);

}
  


// Main function
// Execution begin here
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});