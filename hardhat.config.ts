import { HardhatUserConfig } from "hardhat/config"
import "@nomiclabs/hardhat-waffle"
// To support typescript path mappings, follow:
// https://hardhat.org/guides/typescript.html#support-for-path-mappings

const config: HardhatUserConfig = {
  networks: {
    //defaultNetwork: 'localhost',
    hardhat: {
    },
    localhost: {
      url: 'http://localhost:8545',
    }  
  },
  solidity: {
    compilers: [
      {
        version: "0.8.5",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ],
  },
  mocha: {
    timeout: 20000
  }
}

export default config