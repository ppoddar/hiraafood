const logger = require('./logger')
var fs = require('fs')
var path = require('path')
var yaml = require('js-yaml')
const Item = require('./item')

/*
 */
class ItemController {
    constructor(options) {
        if (!('data_dir' in options)) {
            new Error('no data_dir options given')
        }
        this.items = {}
        this.populate(options['data_dir'])
        
    }
    /*
     * gets all items in the menu.
     * @retrun a dictionary of items indexed by sku
     */
    async getCatalog() {
        return this.items
    }

    /*
     * get an item by sku
     */
    async getItem(sku) {
        if (sku in this.items) {
            return this.items[sku]
        }   
    }

    /*
     * create an Item object by reading a *.json or *.yaml file 
     * content.
     */
    async createItem(item_data) {
        if (item_data) {
            const item = new Item(item_data)
            this.items[item.sku] = item
        }
    }

    readItemFromFile(file_path) {
        logger.info(`readItemFromFile from ${file_path}`)
        const ext = path.extname(file_path)
        if (ext == '.json') {
            let fileContents = fs.readFileSync(file_path, 'utf8');
            return JSON.parse(fileContents)
        } else if ((ext == '.yaml') || (ext == '.yml')) {
            let fileContents = fs.readFileSync(file_path, 'utf8');
            return yaml.safeLoad(fileContents)
        } else {
            logger.warn(`ignore ${file_path}. only json and yaml files are allowed`)
        }
    }

    /*
     * affirms if an item of given sku exists
     */
    async existsItem(sku) {
        return sku in this.items
    }

    /*
     * Populate menu items.
     * Each menu item is described in ./data/items/*.json file
     * relative to parent directory of this script.
     */
    async populate(dir) {
        const data_dir = path.join(__dirname, dir)
        logger.info(`populate menu items from ${dir}`)
        var files = fs.readdirSync(data_dir, { withFileTypes: true })
        logger.info(`found ${files.length} files`)
        for (var i = 0; i < files.length; i++) {
            const file = files[i]
            const file_path = path.join(data_dir, file.name)
            const item_data = this.readItemFromFile(file_path) 
            if (item_data) {
                this.createItem(item_data)
            } else {
                logger.warn(`item data can not be read from ${file_path}`)
            }
        }
    }

    async enumerateItems() {
        const catalog = await this.getCatalog()
        for (var i = 0; i < catalog.length; i++) {
            logger.debug(`${i} ${catalog[i].sku}\t${catalog[i].name}`)
        }
        logger.info(`(${catalog.length} items in menu)`)
    }

}

module.exports = ItemController