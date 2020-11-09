class Item {
    constructor(data) {
        this.sku = data.sku
        this.name = data.name
        this.categories = data.categories
        this.price = data.price
        this.additional_price = data.additional_price
        this.image = data.image
    }
}

module.exports = Item