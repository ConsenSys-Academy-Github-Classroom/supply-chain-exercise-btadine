module.exports = {
  networks: {
    local: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
    },
  },
  compilers: {
    solc: {
      version: '^0.8', // Fetch latest 0.8.x Solidity compiler
    },
  },
};
