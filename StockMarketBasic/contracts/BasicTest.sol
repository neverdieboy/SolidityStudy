// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicTest {
    enum DooblonCoin {
        /// Type of currency customer own
        Silver,
        Copper
    }

    enum OfferStatus {
        /// Status of the offer
        Pending,
        Placed,
        Accepted
    }

    struct Customer {
        /// Customer structure
        uint id;
        string customerName;
        string[] markets; /// Markets where user trades
        bool created; /// To check if customer exists
        mapping(DooblonCoin => uint) wallet;
    }

    struct Offer {
        /// Structure of the offer
        uint id;
        uint customerID;
        DooblonCoin giveCoin; /// Coin which customers "gives"
        DooblonCoin takeCoin; /// Coin which customer "wants"
        uint quantity; /// Quantity of given coin
        uint quantityExpected; /// Quantity expected by customer
        OfferStatus status;
    }

    struct Trade {
        /// Structure of the trade
        uint id;
        Offer offer1; /// Pointer to offer 1
        Offer offer2; /// Pointer to offer 2
    }

    struct StockMarket {
        /// Structure of the Stock Market
        string name;
        uint[] customers;
        uint[] offersPlaced;
        uint[] tradesInitiated;
        mapping(uint => bool) listedTrades; /// To check if trade exists on this market
        bool created; /// Check if market exists
    }

    uint constant silverPrice = 1; /// 1 Silver == 100 Copper
    uint constant copperPrice = 100;

    mapping(DooblonCoin => uint) priceList;

    string[3] marketNames = ["Capital Market", "Pepe Stocks", "Meme Trades"];

    mapping(string => StockMarket) marketList; /// Storage of markets
    mapping(uint => Customer) customerList; /// Storage of customers
    mapping(uint => Offer) offers; /// Storage of offers
    mapping(uint => Trade) trades; /// Storage of trades

    event StockMarketCreated(string name); /// Is triggered when market is created
    event CustomerJoinedStockMarket(string name, uint id); /// Is triggered when customer is added to the market

    event TradeInitiated(string, uint tradeID); /// Is triggered when trade is successful
    event NoMatchingOffer(string); /// Is triggered when no matching offers where found on market

    event OfferPlaced(
        uint customerID,
        DooblonCoin givenCoin,
        DooblonCoin takeCoin,
        uint quantityGiven,
        uint quantityExpected,
        uint offerID
    ); /// Is triggered when offer is successfully placed on market

    event CustomerCreated(string name, uint id); /// Is triggered when customer is created
    event CustomerFunded(DooblonCoin coin, uint quantity); /// Is triggered when customer wallet is funded

    modifier customerIDCheck(uint customerID) {
        require(
            customerList[customerID].created,
            "ID not matching any customer"
        );
        _;
    } /// Check if customer with given ID exists

    constructor() {
        /// Creates 3 markets - names are listed in 'marketNames'
        for (uint i = 0; i < marketNames.length; i++) {
            createStockMarket(marketNames[i]);
        }
        priceList[DooblonCoin.Silver] = silverPrice;
        priceList[DooblonCoin.Copper] = copperPrice;
    }

    function randomNum() public view returns (uint) {
        /// As this code is tested using Ganache, for each new TX new block is created,
        /// so within this case this function provides unique "random" numbers on base of the block creation time & block number
        uint num = block.timestamp;
        uint blockNum = (block.number);
        uint result = (num * blockNum) % 10000;
        return result;
    }

    function createCustomer(string memory name) external {
        /// Function to create customer
        uint id = randomNum();
        Customer storage customer = customerList[id]; /// Store customer in to storage mapping
        customer.customerName = name;
        customer.id = id;
        customer.created = true;
        emit CustomerCreated(name, id);
    }

    function createStockMarket(string memory name) private {
        /// Function to create StockMarket
        StockMarket storage market = marketList[name]; /// Store StockMarket in to storage mapping
        market.name = name;
        market.created = true;
        emit StockMarketCreated(name);
    }

    function checkStockMarketExists(
        string memory name
    ) public view returns (string memory) {
        /// Check if stock market with given name exists
        if (marketList[name].created) {
            return "Market exists!";
        } else {
            return "No such market!";
        }
    }

    function fundCustomerWallet(
        uint customerID,
        DooblonCoin coin,
        uint quantity
    ) external customerIDCheck(customerID) {
        /// Fund customer wallet with given coin & given amount
        Customer storage customer = customerList[customerID];
        customer.wallet[coin] += quantity;
        emit CustomerFunded(coin, quantity);
    }

    function customerJoinStockMarket(
        string memory marketName,
        uint customerID
    ) public customerIDCheck(customerID) {
        /// Add customewr to the list of customers of the market
        Customer storage customer = customerList[customerID];
        StockMarket storage stockMarket = marketList[marketName];
        stockMarket.customers.push(customerID);
        customer.markets.push(stockMarket.name);
    }

    function placeOffer(
        string memory stockMarketName,
        uint customerID,
        DooblonCoin giveCoin,
        DooblonCoin takeCoin,
        uint quantity
    ) public customerIDCheck(customerID) {
        /// Place offer on the market
        StockMarket storage stockMarket = marketList[stockMarketName]; /// Market object
        Customer storage customer = customerList[customerID]; /// Customer object
        require(customer.wallet[giveCoin] >= quantity, "Insufficient balance"); /// Check the balance before creating offer
        uint offerID = randomNum() * 10; /// Unique offer ID
        uint quantityExpected; /// Quantity of the coins customer expects to receive based on type & amount of the given coins
        stockMarket.offersPlaced.push(offerID); /// Store ID of the offer in the market object memory

        /// Offer object setting
        Offer storage offer = offers[offerID];
        offer.status = OfferStatus.Pending;
        offer.id = offerID;
        offer.customerID = customerID;
        offer.giveCoin = giveCoin;
        offer.takeCoin = takeCoin;
        offer.quantity = quantity;

        /// Customer wallet setting

        /// Checking thwe type of coin for ruther calculation of the amount of coins expected
        if (giveCoin == DooblonCoin.Silver) {
            quantityExpected = quantity * copperPrice;
            offer.quantityExpected = quantityExpected;
        } else if (giveCoin == DooblonCoin.Copper) {
            quantityExpected = quantity / copperPrice;
            offer.quantityExpected = quantityExpected;
        }
        /// Withdraw funds from customer wallet
        customer.wallet[giveCoin] -= quantity;
        /// Change offer status
        offer.status = OfferStatus.Placed;
        /// Trigger event
        emit OfferPlaced(
            customerID,
            giveCoin,
            takeCoin,
            quantity,
            quantityExpected,
            offerID
        );
    }

    function initiateTrade(string memory stockMarketName, uint offerID) public {
        /// The "main" function of this script which finds 2 matching offers, and executes trade
        StockMarket storage stockMarket = marketList[stockMarketName];
        Offer storage offer = offers[offerID]; /// Offer object
        uint len;
        uint tempID; /// ID of the matching offer (will be assigned below)
        bool initiated; /// Informs user if the trade was initiated or not (at the end of the function)

        uint tradeID; /// ID of the trade (will be assigned below in case of success)

        len = stockMarket.offersPlaced.length;
        /// Enters loop to search through all the offers on the market, and find matching one (can be optimized by created 2 different arrays for copper and silver separately)
        for (uint i = 0; i < len; i++) {
            tempID = stockMarket.offersPlaced[i];
            Offer memory tempOffer = offers[tempID];
            require(tempOffer.status == OfferStatus.Placed); ///Check if offer is placed and not already initiated
            require(offer.status == OfferStatus.Placed); ///Check if offer is placed and not already initiated
            if (
                offer.giveCoin == tempOffer.takeCoin && /// Check if coins match
                offer.quantity == tempOffer.quantityExpected /// Check if quantity match
            ) {
                tradeID = randomNum() * 11; /// Assign ID as trade will be successful now
                Trade storage trade = trades[tradeID]; /// Store this trade at mapping
                trade.id = tradeID;
                trade.offer1 = offers[offerID]; /// Store first offer
                trade.offer2 = offers[tempID]; /// Store second offer

                uint customerID_1 = offer.customerID; /// Receive ID of the customer from offer 1
                uint customerID_2 = tempOffer.customerID; /// Receive ID of the customer from offer 2

                Customer storage customer_1 = customerList[customerID_1]; /// Create customer object from offer 1
                Customer storage customer_2 = customerList[customerID_2]; /// Create customer object from offer 2

                customer_1.wallet[offer.takeCoin] += offer.quantityExpected; /// Deposit funds to the wallet
                customer_2.wallet[tempOffer.takeCoin] += tempOffer
                    .quantityExpected; /// Deposit funds to the wallet

                stockMarket.tradesInitiated.push(tradeID); /// Store trade ID in market memory
                stockMarket.listedTrades[tradeID] = true; /// Confirm that THIS trade was initiated at THIS market
                ///(as all trades are stored in one storage mapping, it is done to be sure that this trade belong to this market only)

                offer.status = OfferStatus.Accepted; /// Change offer status so it will be avoided during next loops
                tempOffer.status = OfferStatus.Accepted; /// Change offer status so it will be avoided during next loops

                emit TradeInitiated("Trade succesfully initiated", tradeID); /// Trigger when everything is done
                initiated = true; /// Ititiated is true, no error thrown
                break;
            }
        }
        if (initiated == false) {
            emit NoMatchingOffer("No offers to initiate trade"); /// Triggers if no matching offer was found
        }
    }

    function getTradeInfo(
        string memory marketName,
        uint tradeID
    )
        public
        view
        returns (
            string memory,
            DooblonCoin,
            uint,
            string memory,
            DooblonCoin,
            uint
        )
    {
        /// Get information of the GIVEN trade on GIVEN market
        StockMarket storage market = marketList[marketName];
        require(
            market.listedTrades[tradeID] == true,
            "No such trade on that market"
        ); /// Check if trade was initiated on the GIVEN market
        Trade storage trade = trades[tradeID]; /// Trade object to be parsed below

        Offer storage offer1 = trade.offer1; /// Offer 1 from GIVEN trade
        Offer storage offer2 = trade.offer2; /// Offer 2 from GIVEN trade

        DooblonCoin takeCoin1 = offer1.takeCoin; /// Coin received after trade was initiated by customer 1
        DooblonCoin takeCoin2 = offer2.takeCoin; /// Coin received after trade was initiated by customer 2

        uint quantityExpected1 = offer1.quantityExpected; /// Amount of coins received after trade was initiated by customer 1
        uint quantityExpected2 = offer2.quantityExpected; /// Amount of coins received after trade was initiated by customer 2

        /// Returns all the info parsed above
        return (
            "Offer_1 got:",
            takeCoin1,
            quantityExpected1,
            "Offer_2 got:",
            takeCoin2,
            quantityExpected2
        );
    }

    function getCustomerInfo(
        uint customerID
    ) internal view customerIDCheck(customerID) returns (Customer storage) {
        /// Function to get customer object
        Customer storage customer = customerList[customerID];
        return customer;
    }

    function showWallet(
        uint customerID,
        DooblonCoin coin
    ) public view customerIDCheck(customerID) returns (uint) {
        /// Function to show balance of the GIVEN coin of the GIVEN customer
        uint bal = getCustomerInfo(customerID).wallet[coin];
        return bal;
    }

    function showCoinPrice(DooblonCoin coin) public view returns (uint) {
        /// Function to show price of the GIVEN coin
        uint price = priceList[coin];
        return price;
    }

    function showCustomerMarkets(
        uint customerID
    ) public view returns (string[] memory) {
        /// Function to show markets where GIVEN customer is trading
        return getCustomerInfo(customerID).markets;
    }

    function showCustomersOnMarket(
        string memory marketName
    ) public view returns (string[] memory) {
        /// Show list of customers on given StockMarket
        StockMarket storage market = marketList[marketName];

        uint len = market.customers.length;
        string[] memory names = new string[](len);
        for (uint i = 0; i < len; i++) {
            uint customerID = market.customers[i];
            string memory name = getCustomerInfo(customerID).customerName;
            names[i] = name;
        }
        return names;
    }
}
