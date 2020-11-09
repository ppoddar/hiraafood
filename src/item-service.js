const httpStatus     = require('http-status-codes')
const express        = require('express')
const ItemController = require('./item-controller')
const SubApplication = require('./sub-app')
const logger = require('./logger')
/*
 * Creates and manages menu items.
 */
class ItemService extends SubApplication {
    constructor(options)  {
        super(options)
        this.controller = new ItemController(options)

        this.app.post('/',          this.createItem.bind(this))
        this.app.get('/find/:sku',  this.getItem.bind(this))
        this.app.get('/catalog',    this.getCatalog.bind(this))
    }

    /*
     * gets all items
     */
    async getCatalog(req,res,next) {
        try {
            const catalog = await this.controller.getCatalog()
            res.status(httpStatus.OK).json(catalog)
        } catch(e) {
            next(e)
        }
    }

    /*
     * get an item by sku
     */
    async getItem(req,res,next) {
        try {
            const sku = req.params.sku
            let item =  await this.controller.getItem(sku)
            if (item == null) {
                res.status(httpStatus.NOT_FOUND).json({message:`item ${sku} not found`})
            } else {
                res.status(httpStatus.OK).json(item)
            }
        } catch (e) {
            next(e)
        }
    }

    /*
     * Create an item. The request body is the item 
     */
    async createItem(req,res,next) {
        var item_data = this.postBody(req, false)
        if (!('sku' in item_data)) {
            return res.status(httpStatus.BAD_REQUEST).send({message:'no sku for item data'})
        }
        try {
            await this.controller.createItem(item_data)
            res.status(httpStatus.OK).json({message:`created item ${item_data.sku}`})
        } catch(e) {
            next(e)
        }
    
    }
}



module.exports =  ItemService