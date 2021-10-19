// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
    address public owner;
    uint256 public skuCount;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint256 sku;
        uint256 price;
        State state;
        address seller;
        address buyer;
    }

    Item[] private items;

    event LogForSale(uint256 sku);
    event LogSold(uint256 sku);
    event LogShipped(uint256 sku);
    event LogReceived(uint256 sku);

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint256 _sku) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        (bool refunded, ) = items[_sku].buyer.call{value: amountToRefund}("");
        require(refunded, "Failed to refund");
    }

    // For each of the following modifiers, use what you learned about modifiers
    // to give them functionality. For example, the forSale modifier should
    // require that the item with the given sku has the state ForSale. Note that
    // the uninitialized Item.State is 0, which is also the index of the ForSale
    // value, so checking that Item.State == ForSale is not sufficient to check
    // that an Item is for sale. Hint: What item properties will be non-zero when
    // an Item has been added?

    modifier forSale(uint256 _sku) {
        require(items[_sku].buyer == address(0));
        _;
    }

    modifier sold(uint256 _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    modifier shipped(uint256 _sku) {
        require(items[_sku].state == State.Shipped);
        _;
    }

    modifier received(uint256 _sku) {
        require(items[_sku].state == State.Received);
        _;
    }

    constructor() public {
        owner = msg.sender;
        skuCount = 0;
        // 1. Set the owner to the transaction sender
        // 2. Initialize the sku count to 0. Question, is this necessary?
        // No, because of default values. But it adds clarity and we prevent unexpected behavior because of assumptions.
    }

    function addItem(string memory _name, uint256 _price)
        public
        returns (bool)
    {
        // 1. Create a new item and put in array
        // 2. Increment the skuCount by one
        // 3. Emit the appropriate event
        // 4. return true
        // hint:
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        skuCount = skuCount + 1;
        emit LogForSale(skuCount);
        return true;
    }

    // Implement this buyItem function.
    // 1. it should be payable in order to receive refunds
    // 2. this should transfer money to the seller,
    // 3. set the buyer as the person who called this transaction,
    // 4. set the state to Sold.
    // 5. this function should use 3 modifiers to check
    //    - if the item is for sale,
    //    - if the buyer paid enough,
    //    - check the value after the function is called to make
    //      sure the buyer is refunded any excess ether sent.
    // 6. call the event associated with this function!
    function buyItem(uint256 sku)
        public
        payable
        forSale(sku)
        paidEnough(items[sku].price)
        checkValue(sku)
    {
        Item memory item = items[sku];
        (bool transferred, ) = items[sku].seller.call{value: item.price}("");
        require(transferred, "Failed to send");
        item.buyer = msg.sender;
        item.state = State.Sold;
        items[sku] = item;
        emit LogSold(sku);
    }

    // 1. Add modifiers to check:
    //    - the item is sold already
    //    - the person calling this function is the seller.
    // 2. Change the state of the item to shipped.
    // 3. call the event associated with this function!
    function shipItem(uint256 sku)
        public
        sold(sku)
        verifyCaller(items[sku].seller)
    {
        items[sku].state = State.Shipped;
        emit LogShipped(sku);
    }

    // 1. Add modifiers to check
    //    - the item is shipped already
    //    - the person calling this function is the buyer.
    // 2. Change the state of the item to received.
    // 3. Call the event associated with this function!
    function receiveItem(uint256 sku)
        public
        shipped(sku)
        verifyCaller(items[sku].buyer)
    {
        items[sku].state = State.Received;
        emit LogReceived(sku);
    }

    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            uint256 state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
