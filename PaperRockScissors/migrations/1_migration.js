const TokenPRS = artifacts.require("TokenPRS");
module.exports = function (deployer) {
  deployer.deploy(TokenPRS, 10000);
};
const GamePRS = artifacts.require("GamePRS");
module.exports = function (deployer) {
  deployer.deploy(GamePRS, "PASTE HERE TokenPRS address");
};
