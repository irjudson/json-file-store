fs        = require 'fs'
path      = require 'path'
chai      = require "chai"
Store     = require "../src/Store"
{ exec }  = require 'child_process'
should    = chai.should()
clint     = require "coffeelint"

describe "jfs", ->

  NAME = ".specTests"

  afterEach (done) ->
    fs.unlink NAME + '.json', (err) ->
      exec "rm -rf ./#{NAME}", (err, out) ->
        console.log out
        console.error err if err?
        done()

  it "is a class", ->
    Store.should.be.a.function

  it "resolves the path correctly", ->
    x = new Store "./foo/bar", type: 'memory'
    x._dir.should.equal process.cwd() + '/foo/bar'
    x = new Store __dirname + "/foo/bar", type: 'memory'
    x._dir.should.equal process.cwd() + '/spec/foo/bar'

  it "can save an object", (done) ->
    store = new Store NAME
    data  = { x: 56 }
    store.save "id", data, (err) ->
      should.not.exist err
      fs.readFile "./#{NAME}/id.json", "utf-8", (err, content) ->
        content.should.equal '{"x":56}'
        store.save "emptyObj", {}, (err) ->
          should.not.exist err
          store.get "emptyObj", (err, o) ->
            should.not.exist err
            o.should.eql {}
            done()

  it "can save an object synchronously", ->
    store = new Store NAME
    data  = { s: "ync" }
    id = store.saveSync "id", data
    id.should.equal "id"
    content = fs.readFileSync "./#{NAME}/id.json", "utf-8"
    content.should.equal '{"s":"ync"}'

  it "creates a deep copy for the cache", (done) ->
    store = new Store NAME + '.json'
    z = []
    y = z: z
    data  =
      x: 56
      y:y
    store.save data, (err, id) ->
      store.get id, (err, res) ->
        res.should.eql data
        res.should.not.equal data
        res.y.should.eql y
        res.y.should.not.equal y
        res.y.z.should.eql z
        res.y.z.should.not.equal z
        done()

  it "can load an object", (done) ->
    store = new Store NAME
    data  = { x: 87 }
    store.save data, (err, id) ->
      store.get id, (err, o) ->
        o.x.should.equal 87
        done()

  it "can load an object synchronously", ->
    store = new Store NAME
    data  = { x: 87 }
    id = store.saveSync data
    o = store.getSync id
    o.x.should.equal 87

  it "returns an erro if it cannot load an object", (done) ->
    store = new Store NAME + ".json"
    store.save "anId", {}, (err, id) ->
      should.not.exist err
      store.get "foobarobject", (err, o) ->
        err.should.be.truthy
        err.message.should.equal "could not load data"
        done()

  it "can load all objects", (done) ->
    store = new Store NAME
    x1 = { j: 3 }
    x2 = { k: 4 }
    store.save x1, (err, id1) ->
      store.save x2, (err, id2) ->
        store.all (err, all) ->
          should.not.exist err
          all[id1].j.should.equal 3
          all[id2].k.should.equal 4
          done()

  it "can load all objects synchronously",->
    store = new Store NAME
    x1 = { j: 3 }
    x2 = { k: 4 }
    id1 = store.saveSync x1
    id2 = store.save x2
    all = store.allSync()
    (all instanceof Error).should.be.falsy
    all[id1].j.should.equal 3
    all[id2].k.should.equal 4

  it "can delete an object", (done) ->
    store = new Store NAME
    data  = { y: 88 }
    store.save data, (err, id) ->
      fs.readFile "./#{NAME}/#{id}.json", "utf-8", (err, content) ->
        content.should.not.eql ""
        store.delete id, (err) ->
          fs.readFile "./#{NAME}/#{id}.json", "utf-8", (err, content) ->
            err.should.exist
            done()

  it "can delete an synchonously", ->
    store = new Store NAME
    data  = { y: 88 }
    id = store.saveSync data
    content = fs.readFileSync "./#{NAME}/#{id}.json", "utf-8"
    content.should.not.eql ""
    err = store.deleteSync id
    (-> fs.readFileSync "./#{NAME}/#{id}.json", "utf-8").should.throw()

  it "can pretty print the file content", ->
    store = new Store NAME, pretty: true
    id = store.saveSync "id", { p: "retty" }
    content = fs.readFileSync "./#{NAME}/id.json", "utf-8"
    content.should.equal """
      {
        "p": "retty"
      }
      """

  describe "single file db", ->

    it "can store data in a single file", (done) ->
      store = new Store NAME, type:'single', pretty:true
      fs.readFile "./#{NAME}.json", "utf-8", (err, content) ->
        content.should.equal "{}"
        d1  = { x: 0.6 }
        d2  = { z: -3 }
        store.save "d1", d1, (err) ->
          should.not.exist err
          store.save "d2", d2, (err) ->
            should.not.exist err
            f = path.join process.cwd(), "#{NAME}.json"
            fs.readFile f, "utf-8", (err, content) ->
              should.not.exist err
              content.should.equal """
                {
                  "d1": {
                    "x": 0.6
                  },
                  "d2": {
                    "z": -3
                  }
                }
                """
              done()

    ###
    fs.rename 'overrides' an existing file
    even if its write protected
    ###
    it "it checks for write protection", (done) ->
      f = path.resolve "#{NAME}/mydb.json"
      store = new Store f, type:'single'
      store.saveSync 'id', {some: 'data'}
      fs.chmodSync(f, '0444')
      store.save 'foo', bar: 'baz', (err, id) ->
        should.exist err
        fs.chmodSync(f, '0644')
        done()

    it "loads an existing db", (done) ->
      store = new Store NAME, single: true
      store.save "id1", {foo: "bar"}, (err) ->
        store = new Store NAME, single: true
        fs.readFile "./#{NAME}.json", "utf-8", (err, content) ->
          content.should.equal '{"id1":{"foo":"bar"}}'
          store.all (err, items) ->
            should.not.exist err
            items.id1.should.eql {foo: "bar"}
            done()

    it "get data from a single file", (done) ->
      store = new Store NAME, single:true
      data  = { foo: "asdlöfj" }
      store.save data, (err, id) ->
        store.get id, (err, o) ->
          o.foo.should.equal "asdlöfj"
          done()

    it "can delete an object", (done) ->
      store = new Store NAME, single:true
      data  = { y: 88 }
      f = path.join process.cwd(), "#{NAME}.json"
      store.save data, (err, id) ->
        fs.readFile f, "utf-8", (err, content) ->
          (content.length > 7).should.be.truthy
          store.delete id, (err) ->
            fs.readFile f, "utf-8", (err, content) ->
              should.not.exist err
              content.should.equal "{}"
              done()

    it "can be defined if the name is a file", (done) ->
      store = new Store './' + NAME + '/foo.json'
      store._single.should.be.true
      f = path.join process.cwd(), "./#{NAME}/foo.json"
      fs.readFile f, "utf-8", (err, content) ->
        should.not.exist err
        content.should.equal "{}"
        done()

  describe "source code", ->

    it "is clean", (done) ->
      fs.readFile path.join(__dirname, "../src/Store.coffee"), "utf8", (err, code) ->
        should.not.exist err
        errors = clint.lint code
        l = errors.length
        unless l is 0
          for x in errors
            console.error "#{x.level}: #{x.message}: #{x.context} line: #{x.lineNumber}"
        l.should.equal 0
        done()

  describe "in memory db",->

    it "does not write the data to a file", (done) ->
      store = new Store NAME, type: 'memory'
      data  = { y: 78 }
      store.save "id", data, (err, id) ->
        should.not.exist err
        fs.readFile "./#{NAME}/id.json", "utf-8", (err, content) ->
          should.exist err
          should.not.exist content
          store.allSync().should.eql id: y: 78
          store.saveSync 'foo', { bar: 'baz' }
          store.all (err, d) ->
            should.not.exist err
            d.should.eql
              foo: bar: 'baz'
              id: y: 78
            store.deleteSync 'id'
            store.allSync().should.eql foo: bar: 'baz'
            should.throw -> fs.readFileSync "./#{NAME}/id.json", "utf-8"
            done()
