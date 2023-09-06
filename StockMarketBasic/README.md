Project for understanding basics of Solidity, structures, types and functions.

Project represents simple "StockMarket", where "Customers" can swap "Silver Dooblons" for "Copper Dooblons" and vice versa.

How it works:<br />
  -> StockMarkets are created in constructor;<br />
  -> Customers can be created via createCustomer(name); Note customer ID for future usage.<br />
  -> Customer wallet is funded using fundCustomerWallet(customerID, Silver, 100);<br />
  -> Customer must be added to the market before placing offers. Done via customerJoinStockMarket(StockMarket name, customerID);<br />
  -> Offer is placed using placeOffer(StockMarket name, customerID, Silver, Copper, 10); Note offer ID for future usage.<br />
  -> Trying to initiate trade is done via initiateTrade(StockMarket name, offerID);
