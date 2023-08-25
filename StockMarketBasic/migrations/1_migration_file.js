const BasicTest = artifacts.require("BasicTest");
module.exports = function (deployer) {
  deployer.deploy(BasicTest);
};
