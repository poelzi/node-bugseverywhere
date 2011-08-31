yaml = require 'libyaml'
fs = require 'fs'
async = require 'async'
path = require 'path'
guid = require 'guid'
#eyes = require 'eyes'

# list of supported bugseveryhere storage formats
FORMATS = {
    "1.0":"Bugs Everywhere Tree 1 0"
    # untested
    #"1.1":"Bugs Everywhere Directory v1.1",
    #"1.2":"Bugs Everywhere Directory v1.2",
    #"1.3":"Bugs Everywhere Directory v1.3",
    "1.4":"Bugs Everywhere Directory v1.4"
}


class FileStorage
    constructor: (@path, @encoding='utf-8', @options=null) ->


    _read_file: (file, callback) =>
        fs.readFile path.join(@path, file), @encoding, (err, data) ->
            callback(err, null) if err
            callback("Empty file", null) if not data
            callback(null, yaml.load(data)[0])
        return
    
    _read_uuids: (path, callback) =>
        fs.readdir path, (err, files) =>
            callback(err, null) if err
            ids = files.filter (fn) -> return guid.isGuid(fn)
            callback(null, ids)

    # return storage version number
    read_version: (callback) =>
        fs.readFile path.join(@path, "version"), "utf-8", (err, data) ->
            return callback(err, data.trim()) if not err
            callback(err, data)

    read_file: (uuid, file, callback) =>
        @._read_file path.join(uuid, file), callback

    read_bug: (uuid, bug, callback) =>
        @._read_file path.join(uuid, "bugs", bug, "values"), callback

    read_comment_values: (uuid, bug, comment, callback) =>
        @._read_file path.join(uuid, "bugs", bug, "comments", comment, "values"), callback

    read_comment_body: (uuid, bug, comment, callback) =>
        fs.readFile path.join(@path, uuid, "bugs", bug, "comments", comment, "body"), @encoding, callback

    # mass read comments
    read_comments: (uuid, bug, comments, callback) =>
        # FIXME
        #console.log("read comments", uuid, bug, comments)
        tpath = path.join(@path, uuid, "bugs", bug.uuid, "comments")
        # check for path existence
        #console.log(tpath)
        path.exists tpath, (exists) =>
            if not exists
                console.log("not existing")
                return callback(null, {})
            @._read_uuids tpath, (err, files) =>
                console.log("rc", err, files)
                callback(err, null) if err
                if comments == null
                    comments = files
                else
                    # filter non existing comments from list
                    comments = comments.filter (comment) -> return comment in files
                rv = {}
                queue = async.queue((commentid, qcallback) =>
                    #console.log("pre", bug)
                    ccom = new Comment(bug, commentid)
                    ccom.read =>
                        # push result
                        rv[ccom.uuid] = ccom
                        qcallback()
                , 10)
                
                queue.drain = =>
                    #console.log("rv", rv)
                    callback(null, rv)

                for cc in comments
                    queue.push cc



    ## return top list of uuids
    list_top_uuids: (callback) =>
        @._read_uuids(@path, callback)

    ## return list of bug uuids
    list_uuids: (uuid, callback) =>
        @._read_uuids path.join(@path, uuid, "bugs"), callback


class Bugdir
    constructor: (@storage, @uuid=null, @from_storage=false) ->
        @format = null
   
    inspect: =>
        return "[Bugdir " + @uuid + "]"
    #version: (callback) =>
        #fs.read(
    # read most important values
    read: (callback) =>
        async.auto {
            get_version: (callback) =>
                @storage.read_version (err, version) =>
                    console.log("got version", version)
                    for k,v of FORMATS
                        if v == version
                            @format = k
                            return callback(null, k)
                    callback("unsupported storage version", null)
                    
                
            get_uuid: ['get_version', (callback) =>
                if @uuid
                    callback(null, @uuid)
                else
                    @storage.list_top_uuids (err, ids) =>
                        callback("empty directory", null) unless ids.length
                        @uuid = ids[0]
                        callback(null, @uuid)
            ]
            get_settings: ['get_uuid', (callback) =>
                @storage.read_file @uuid, 'settings', (err, data) =>
                    @settings = data or {}
                    @inactive_status = data.inactive_status or null
                    @active_status = data.active_status or null
                    callback(err, data)
            ]
        }, (err) =>
            console.log("error reading bugdir " + @storage.path + ":" + err)
            callback(err, @)

    ## returns list of all uuids
    list_uuids: (callback) =>
        @storage.list_uuids(@uuid, callback)

    # load bug from uuid
    # bug_from_uuid: (uuid, load_comments=false, callback)
    bug_from_uuid: (uuid, args...) =>
        callback = args.pop()
        load_comments = args.pop() or false
        #console.log(uuid, load_comments, callback)
        #console.log("bla", callback)
        rv = new Bug(@, uuid, load_comments)
        #console.log("bugdir", rv.bugdir)
        rv.read(callback)

class Bug
    constructor: (@bugdir=null, @uuid=null, @_load_comments=false, @summary=null) ->
        @comments = {}

    inspect: () =>
        return "<Bug " + @uuid + ">"

    read: (callback) =>
        callback("no bugdir", @) unless @bugdir
        jobs = {}
        # add read jobs depending on settings
        if @uuid
            jobs.values = (callback) =>
               @bugdir.storage.read_bug @bugdir.uuid, @uuid, (err, values) =>
                    @values = values
                    for k,v of values
                      @[k] = v

                    callback(err, values)

        if @uuid and @_load_comments
            jobs.comments = (callback) =>
                @bugdir.storage.read_comments @bugdir.uuid, @, null, (err, comments) =>
                    #console.log("have read comments", comments)
                    @comments = comments or {}
                    callback(err, comments)

        # run all jobs and fire callback with bug as argument
        mycallback = callback
        async.parallel jobs, (err, res) =>
            mycallback(err, @)

    read_comments: (callback) =>
        if @uuid and @_load_comments
            jobs.comments = (callback) =>
                @bugdir.storage.read_comments @bugdir.uuid, @uuid, null, (err, comments) =>
                    @comments = comments
                    callback(err, comments)
class Comment
    constructor: (@bug=null, @uuid=null, @from_storage=false, @in_reply_to=null, @body=null, @content_type=null) ->

    read: (callback) =>
        #eyes.inspect(@bug, "bla", @bug.bugdir)
        callback("no bug", @) if not @bug or not @uuid
        callback("no budir in bug", @) if not @bug.bugdir
        callback("no storage defined", @) if not @bug.bugdir.storage
        console.log("call read on comment")
        #console.log(@bug, @bug.bugdir)
        async.parallel [
            (callback) =>
                @bug.bugdir.storage.read_comment_values @bug.bugdir.uuid, @bug.uuid, @uuid, (err, values) =>
                    @values = values or {}
                    callback(err, values)
            ,
            (callback) =>
                @bug.bugdir.storage.read_comment_body @bug.bugdir.uuid, @bug.uuid, @uuid, (err, body) =>
                    @body = body or ""
                    callback(err, body)
        ], (err, results) ->
            callback(err, @)
        return



module.exports = {
    FileStorage: FileStorage
    Bugdir: Bugdir
}


