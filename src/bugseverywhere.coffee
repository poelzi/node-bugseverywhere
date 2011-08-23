yaml = require 'libyaml'
fs = require 'fs'
async = require 'async'
path = require 'path'
guid = require 'guid'

class FileStorage
    constructor: (@path, @encoding='utf-8', @options=null) ->

    read_file: (uuid, file, callback) =>
        fs.readFile path.join(@path, uuid, file), @encoding, (err, data) ->
            callback(err, null) if err
            callback("Empty file", null) if not data
            callback(null, yaml.load(data)[0])
        return


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


module.exports = {
    FileStorage: FileStorage
    Bugdir: Bugdir
}


