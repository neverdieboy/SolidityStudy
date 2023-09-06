const TokenPRS = artifacts.require("TokenPRS");
module.exports = function (deployer) {
  deployer.deploy(TokenPRS, 10000);
};
// const GamePRS = artifacts.require("GamePRS");
// module.exports = function (deployer) {
//   deployer.deploy(GamePRS, "0x5Ac9e8a6db0403953606c657B3FEDaa31226546E");
// };
