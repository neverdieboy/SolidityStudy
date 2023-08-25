Project for understanding basics of Solidity, structures, types and functions.

Project represents simple "StockMarket", where "Customers" can swap "Silver Dooblons" for "Copper Dooblons" and vice versa.

How it works:\n
  -> StockMarkets are created in constructor;
  -> Customers can be created via createCustomer(name); Note customer ID for future usage.
  -> Customer wallet is funded using fundCustomerWallet(customerID, Silver, 100);
  -> Customer must be added to the market before placing offers. Done via customerJoinStockMarket(StockMarket name, customerID);
  -> Offer is placed using placeOffer(StockMarket name, customerID, Silver, Copper, 10); Note offer ID for future usage.
  -> Trying to initiate trade is done via initiateTrade(StockMarket name, offerID);
