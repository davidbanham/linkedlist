static_ = require("node-static")

file = new static_.Server("./")

require("http").createServer((request, response) ->
  request.addListener("end", ->
    file.serve request, response
  ).resume()
).listen process.env.PORT or 3000
