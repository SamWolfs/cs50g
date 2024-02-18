fennel = require("fennel")
debug.traceback = fennel.traceback
table.insert(package.loaders, fennel.make_searcher({correlate=true}))
-- jump into Fennel
require("game")
