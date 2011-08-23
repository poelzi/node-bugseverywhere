yaml = require 'libyaml'
fs = require 'fs'
async = require 'async'
path = require 'path'
guid = require 'guid'

class FileStorage
    constructor: (@path, @encoding='utf-8', @options=null) ->


    _read_file: (file, callback) =>
        fs.readFile path.join(@path, file), @encoding, (err, data) ->
            callback(err, null) if err
            callback("Empty file", null) if not data
            callback(null, yaml.load(data)[0])
        return

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
        callback(null, null)

    _read_uuids: (path, callback) =>
        fs.readdir path, (err, files) =>
            console.log("read", err, files, path)
            callback(err, null) if err
            ids = files.filter (fn) -> return guid.isGuid(fn)
            callback(null, ids)

    ## return top list of uuids
    list_top_uuids: (callback) =>
        @._read_uuids(@path, callback)

    ## return list of bug uuids
    list_uuids: (uuid, callback) =>
        @._read_uuids path.join(@path, uuid, "bugs"), callback

class Bugdir
    constructor: (@storage, @uuid=null, @from_storage=false) ->
   
    inspect: =>
        return "[Bugdir " + @uuid + "]"
    #version: (callback) =>
        #fs.read(
    # read most important values
    read: (callback) =>
        async.auto {
            get_uuid: (callback) =>
                if @uuid
                    callback(null, @uuid)
                else
                    @storage.list_top_uuids (err, ids) =>
                        callback("empty directory", null) unless ids.length
                        @uuid = ids[0]
                        callback(null, @uuid)

            get_settings: ['get_uuid', (callback) =>
                @storage.read_file @uuid, 'settings', (err, data) =>
                    @settings = data or {}
                    @inactive_status = data.inactive_status or null
                    @active_status = data.active_status or null
                    callback(err, data)
            ]
        }, (err) =>
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
        rv.read(callback)

class Bug
    constructor: (@bugdir=null, @uuid=null, @load_comments=false, @summary=null) ->
        @comments = {}

    read: (callback) =>
        console.log("read bug")
        console.log(@bugdir)
        callback("no bugdir", @) unless @bugdir
        jobs = {}
        # add read jobs depending on settings
        if @uuid
            jobs.values = (callback) =>
               @bugdir.storage.read_bug @bugdir.uuid, @uuid, (err, values) =>
                    console.log("read bug values", err, values)
                    @values = values
                    for k,v of values
                      @[k] = v

                    callback(err, values)

        if @uuid and @load_comments
            jobs.comments = (callback) =>
                @bugdir.storage.read_bug @bugdir.uuid, @uuid, (err, comments) =>
                    @comments = comments
                    callback(err, comments)

        # run all jobs and fire callback with bug as argument
        mycallback = callback
        async.parallel jobs, (err, res) =>
            mycallback(err, @)

class Comment
    constructor: (@bug=null, @uuid=null, @from_storage=false, @in_reply_to=null, @body=null, @content_type=null) ->

    read: (callback) =>
        callback("no bug", @) if not @bug or not @uuid
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
        , (err, results) ->
            callback(err, @)
        ]
        return



module.exports = {
    FileStorage: FileStorage
    Bugdir: Bugdir
}


