const os                = require('os')
const express           = require('express')
const cors              = require('cors')
const http              = require('http')
const https             = require('https')
const fs                = require('fs')
var path                = require('path')
const yaml              = require('js-yaml')

const autobind          = require('auto-bind')
const httpStatus        = require('http-status-codes')
const CommandLine       = require('./src/command-line.js')
const ItemService       = require('./src/item-service')
const logger = require('./src/logger.js')
const ErrorHandler      = require('./src/errors').ErrorHandler
const morgan            = require('morgan')('tiny')

let COOKIE_NAME = 'hiraafood'
let ENTRY_PAGES  = ['/', './index.html', './login.html']

class Hiraafood {
    /*
     * a server is configured from command-line arguments
     * Arguemnts: (optional unless explict )
     *   -p        : server port. Required
     *   --secure  : starts https server. Otherwuse http server 
     *   -c        : A JSON file for server configuration
     *               Defaults to config/config.json
     *   -d        : A JSON file for database configuration
     *               Defaults to config/database.json
     * --docroot
     */
    constructor() {
        this.cli        = new CommandLine()
        this.secure     = this.cli.isPresent('--secure')
        this.port       = this.cli.getOption('-p')
        this.docroot    = 'public'
        const configFileName  = this.cli.getOption('-c', 'config/config.yml')
        this.config     = this.readFile(configFileName)

        this.itemService  = new ItemService(this.config['item-service'] || {})
        const content = fs.readFileSync(path.join(__dirname, 'info.json'))
        this.info = JSON.parse(content)
        autobind(this)
    }

    
    /*
     * starts the services and sets the routes
     */
    start() {
        this.app = express()
        this.app.set('port', this.port)
        this.app.use(cors())
        this.app.use(morgan)
        
        this.app.use(express.json());

        this.app.use('/', express.static(path.join(__dirname, this.docroot)))

        this.app.use('/item', this.itemService.app)
        
         // route definitions
         this.app.get('/info',             this.getServerInfo)
         this.app.use(ErrorHandler)

        var server 
        if (this.secure) {
            const securityOptions = {
              key:  fs.readFileSync(path.join(__dirname, this.config.security.key)),
              cert: fs.readFileSync(path.join(__dirname, this.config.security.cert))
            };
            server = https.createServer(securityOptions, this.app)
        } else {
            server = http.createServer(this.app)
        }

        
        var protocol = this.secure ? 'https' : 'http'
        var host = os.hostname()
        logger.info("--------------------------------------------------")
        logger.info(`starting ${protocol}://${host}:${this.port}`)
        logger.info("--------------------------------------------------")

        
        process.on('uncaughtException', function (e) {
            console.log(`***ERROR:${e}`)
            console.trace(e)
            process.exit(1)
        })
        process.on('SIGINT', function() { // 2
            logger.error('exit..................')
            process.exit(2)
        })        
        server.listen(this.port, '0.0.0.0')
    }

    /*
     * The first middleware checks if request has a named cookie.
     * If not, if returns http status HttpStatus.UNAUTHORIZED 
     * else an HttpStatus.OK response.
     * 
     * Always returns OK for initail page urls
     */
    async getCurrentSession(req,res,next) {
        if (ENTRY_PAGES.includes(req.url)) {
            console.log(`no check for entry page ${req.url}`)
            next()
            return // IMPORTANT:must call return
        }

        try {
            console.log(`${req.originalUrl} parsed ${Object.keys(req.cookies).length} cookies:`)
            // req.cookies is a dictionary(name:value) are parsed by cookie-parser
            if (COOKIE_NAME in req.cookies) {
                console.log(`!found cookie ${COOKIE_NAME} = ${req.cookies[COOKIE_NAME]}`)
                res.status(httpStatus.OK)
                next()
                return
            } else {
                console.log(`cookie ${COOKIE_NAME} not found`)
                res.status(httpStatus.UNAUTHORIZED).end()
            }
        } catch (e) {
            console.error(e)
            next(e)
        }
    }

    async getServerInfo(req,res,next) {
        res.status(httpStatus.OK).json(this.info)
    }

    /*
     * reads content of a json/yml file. The file name is relative to
     * directory of ths script 
     */
    readFile(fname) {
        const file_path = path.join(__dirname, fname)
        try {
            let fileContent = fs.readFileSync(file_path, 'utf8');
            if (fname.endsWith('.yml')) {
                return  yaml.safeLoad(fileContent)
            } else if (fname.endsWith('.json')) {
                return  JSON.parse(fileContent)
            } else {
                throw new Error(`can not read ${fname}. Must have extension .json or .yml`)
            }
        } catch (err) {
            throw err
        }
    }
 }


new Hiraafood().start()
