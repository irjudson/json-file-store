# JSON file store

A simple JSON file store for node.js.

[![Build Status](https://secure.travis-ci.org/flosse/json-file-store.png)](http://travis-ci.org/flosse/json-file-store)

WARNING:
Don't use it if you want to persist a large amount of objects.
Use a real DB instead.

## Install

    npm install jfs --save

## Usage

```javascript
var Store = require("jfs");
var db = new Store("data");

var d = {
  foo: "bar"
};

// save with custom ID
db.save("anId", d, function(err){
  // now the data is stored in the file data/anId.json
});

// save with generated ID
db.save(d, function(err, id){
  // id is a unique ID
});

// save synchronously
var id = db.saveSync("anId", d);

db.get("anId", function(err, obj){
  // obj = { foo: "bar" }
})

// get synchronously
var obj = db.get("anId");

// get all available objects
db.all(function(err, objs){
  // objs is a map: ID => OBJECT
});

// get all synchronously
var objs = db.allSync()

// delete by ID
db.delete("myId", function(err){
  // the file data/myId.json was removed
});

// delete synchronously
db.delete("myId");
```

### Single file mode

If you want to store all objects in a single file, just set the `single` flag:

```javascript
var db = new Store("data",{single:true});
```

or point to a JSON file:

```javascript
var db = new Store("./path/to/data.json");
```

## License

This project is licensed under the MIT License.
