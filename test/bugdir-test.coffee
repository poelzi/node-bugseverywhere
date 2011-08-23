vows = require 'vows'
assert = require 'assert'
be = require '../bugseverywhere'


# all uuids from sample directory
UIDS = ['77399855-6300-41a8-91a3-decbb915a3ff',
 '64ccf451-b61c-491f-aa68-0ac1b5dbfa6d',
 '528b2e84-a944-4628-a18f-cc1def1c7e16',
 '9c25fd46-5e2b-478f-8beb-01b89e27c1f2',
 'd8dba78d-f82a-4674-9003-a0ec569b4a96',
 '984472f6-98f5-48fc-b521-70a1e5f60614',
 '9a942b1d-a3b5-441d-8aef-b844700e1efa',
 '27bb8bc2-05c2-417a-9d09-928471380d7a',
 'cb56c990-a757-4aef-9888-a30918a7b3d7',
 '529c290e-b1cf-4800-be7e-68f1ecb9565c',
 'c7251ff9-24e4-402d-8d4e-605a78b9a91d',
 '17921fbc-e7f0-4f31-8cdd-598e5ba7237b',
 '7cb42a60-c977-40db-b2a1-19917c10cace',
 '7ec2c071-9630-42b0-b08a-9854616f9144',
 'da2b09ff-af24-40f3-9b8d-6ffaa5f41164',
 '870d5dbe-6449-4ec4-ae6f-e84bebadbce0',
 '42716dc2-6201-4537-b5fd-e1280812a53d',
 '7d182ab9-9c0c-4b4f-885e-c5762d7a2437',
 '6622c06a-ed84-4d45-8011-a082fca219b6',
 '7bfc591e-584a-476e-8e11-b548f1afcaa6',
 'e2f6514c-5f9f-4734-a537-daf3fbe7e9a0',
 '35b962a0-a64a-4b5c-82c5-ea740e8a6322',
 '576e804a-8b76-4876-8e9d-d7a72b0aef10',
 '47c8fd5f-1f5a-4048-bef7-bb4c9a37c411',
 'ed5eac05-80ed-411d-88a4-d2261b879713',
 'dd7aa57c-f184-495a-8520-2676c1066fb4',
 '2aa60b34-2c8d-4f41-bb97-a57309523262',
 '2103f60c-36e5-4b05-b57c-8c6fee2d80d4',
 'f65b680b-4309-43a2-ae2d-e65811c9d107',
 '866cba32-4347-4f51-9b1d-69454638ca78',
 'ee681951-f254-43d3-a53a-1b36ae415d5c',
 '2929814b-2163-45d0-87ba-f7d1ef0a32a9',
 '35a50658-c13c-4f29-9bd0-032c411e4a6b',
 '81f69fbd-1ca5-4f89-a6e1-79ea1e6bf4d9',
 'bd0ebb56-fb46-45bc-af08-1e4a94e8ef3c',
 '312fb152-0155-45c1-9d4d-f49dd5816fbb',
 'c592a1e8-f2c8-4dfb-8550-955123073947',
 'b1bc6f39-8166-46c5-a724-4c4a3e1e7d74',
 '814e39c0-68ee-4165-9166-19e2aee9c07d',
 'e30e2b6b-acc9-4b93-88c6-b63b6e30b593',
 '597a7386-643f-4559-8dc4-6871924229b6',
 '56506b73-36cc-4e32-a578-258a219edba8',
 '04edb940-06dd-4ded-8697-156d54a1d875',
 '2f048ac5-5564-4b34-b7f9-605357267ed2',
 '40dac9af-951e-4b98-8779-9ba02c37f8a1',
 '24555ea1-76b5-40a8-918f-115a28f5f36a',
 'c4ea43d5-4964-49ea-a1eb-2bab2bde8e2e',
 '6eb8141f-b0b1-4d5b-b4e6-d0860d844ada',
 '8e948522-c6a1-4c97-af93-2cf4090f44b5',
 '55e76f74-37fb-4254-8498-54b703ba54f6',
 '4a4609c8-1882-47de-9d30-fee410b8a802',
 '0e0c806c-5443-4839-aa60-9615c8c10853',
 'e645d562-6f84-4df2-b8ee-86ef42546c16',
 'e0858b12-0be3-49bb-ad7a-030e488bb2f1',
 '372f8a5c-a1ce-4b07-a7b1-f409033a7eec',
 '5920ef40-ce56-44e0-9e2d-e9b888ab2880',
 '51930348-9ccc-4165-af41-6c7450de050e',
 '16fc9496-cdc2-4c6e-9b9f-b8f483b6dedb',
 '0ca2d112-b5bb-4df1-8ac0-e46db6cdd442',
 '76a6140e-0800-453c-9720-29cc161663d1',
 'dba25cfd-aa15-457c-903a-b53ecb5a3b2c',
 '74cccfbf-069d-4e99-8cab-adaa35f9a2eb',
 '9f910ee0-ff0f-4fa3-b1e3-79a4118e48e9',
 '65776f00-34d8-4b58-874d-333196a5e245',
 'ae998b27-a11b-4243-abf6-11841e5b8242',
 'b187fbce-fb10-4819-ace2-c8b0b4a45c57',
 '0be47243-c172-4de9-b71b-d5dea60f91d5',
 '2b81b428-fc43-4970-9469-b442385b9c0d',
 '4bc91110-1240-4733-af00-1df1712a7abb',
 'e4ed63f6-9000-4d0b-98c3-487269140141',
 '427e0ca7-17f5-4a5a-8c68-98cc111a2495',
 'e23d7982-7e32-4c78-b62e-83ecc42b4cd7',
 'dcca51b3-bf8f-4482-8f67-662cfbcb9c6c',
 'ac72991a-72e5-4b14-b53c-0fa38d0f31bb',
 '0a234f51-2fdf-4001-a04f-b7e02c2fa47b',
 '7ba4bc51-b251-483a-a67a-f1b89c83f6af',
 'bef126a0-27be-402f-84fa-85f6342c97c0',
 'b8d95763-1825-4e09-bf52-cbd884b916af',
 '8e83da06-26f1-4763-a972-dae7e7062233',
 '27549110-e491-4651-81ab-84de2ed8e14a',
 '52034fd0-ec50-424d-b25d-2beaf2d2c317',
 '52a15454-196c-4990-b55d-be2e37d575c3',
 '01c9a900-61f9-41f7-9b2f-dd8f89e25b1b',
 '381555eb-f2e3-4ef0-8303-d759c00b390a',
 '1100c966-9671-4bc6-8b68-6d408a910da1',
 'c271a802-d324-48a6-b01d-63e4a72aa43e',
 '171819aa-c092-4ddf-ace3-797635fa2572',
 '3438b72c-6244-4f1d-8722-8c8d41484e35',
 '12c986be-d19a-4b8b-b1b5-68248ff4d331',
 'e0155831-499f-421a-ad02-cd15fc3fecf1',
 '9ce2f015-8ea0-43a5-a03d-fc36f6d202fe',
 'f77fc673-c852-4c81-bfa2-1d59de2661c8',
 '5fb11e65-68a0-4015-b404-737238299cdc',
 '16989098-aa1d-4a08-bff9-80446b4a82c5',
 'c894f10f-197d-4b22-9c5b-19f394df40d4',
 '0cad2ac6-76ef-4a88-abdf-b2e02de76f5c',
 '22b6f620-d2f7-42a5-a02e-145733a4e366',
 'd9959864-ea91-475a-a075-f39aa6760f98',
 '206d9b07-6e30-4c8b-9594-ee98e3c646e7',
 '09f84059-fc8e-4954-b24d-a2b33ef21bf4',
 '73a767f4-75e7-4cde-9e24-91bff99ab428',
 '545311df-8c88-4504-9f83-11d7c5d8aa50',
 '63619cf7-89eb-4e64-91e9-b8a73d2a6c72',
 '700cd3f1-70b6-4887-89a2-c1d039732add',
 '01e7151c-6113-4c8f-9fc5-4d594431bd2b',
 'd63d0bdd-e025-4f7c-9fcf-47a71de6d4d4',
 'a4d38ba7-ec28-4096-a4f3-eb8c9790ffb2',
 '615ad650-9fb9-4026-9779-58d42b4e528e',
 '9daa72ee-0721-4f68-99ee-f06fec0b340e',
 'c45e5ece-63e3-4fd2-b33f-0bfd06820cf4',
 'c1b76442-eab6-4796-9517-8454425d7757',
 'f7ccd916-b5c7-4890-a2e3-8c8ace17ae3a',
 'cf77c72d-b099-413a-802e-a8892ac8c26b',
 '8fc5d6fa-cae1-451f-9817-3e4da6d0aac1',
 'b3562f08-ad27-4b9f-8d21-8b58ba6d9eac',
 'cfb52b6c-d1a6-4018-a255-27cc1c878193',
 '68ba7f0c-ca5f-4f49-a508-e39150c07e13',
 '3613e6e9-db9e-4775-8914-f31f0b4b81ac',
 '508ea95e-7bc6-4b9b-9e36-a3a87014423d',
 '597b03f5-76cb-4951-b370-a01573ad2f75',
 '9bc14860-b2bb-4442-85ea-0b8e7083457b',
 '00f26f04-9202-4288-8744-b29abc2342d6',
 'cf56e648-3b09-4131-8847-02dff12b4db2',
 '31cd490d-a1c2-4ab3-8284-d80395e34dd2',
 '8385a1fb-63df-4ca6-81cd-28ede83bb0c2',
 'f5c06914-dc64-4658-8ec7-32a026a53f55',
 '4286c0f8-5703-4bc1-b256-414dc408f067',
 'b3c6da51-3a30-42c9-8c75-587c7a1705c5',
 '9b1a0e71-4f7d-40b1-ab32-18496bf19a3f',
 'a403de79-8f39-41f2-b9ec-15053b175ee2',
 'a63bd76a-cd43-4f97-88ba-2323546d4572',
 '4fc71206-4285-417f-8a3c-ed6fb31bbbda',
 '496edad5-1484-413a-bc68-4b01274a65eb',
 '8e1bbda4-35b6-4579-849d-117b1596ee99',
 'ecc91b94-7f3f-44a7-af58-03191d327a7f',
 'fd96c69d-6f78-4c0c-af6e-e01e9b8516d3',
 '301724b1-3853-4aff-8f23-44373df7cf1c',
 'f70dd5df-805b-49f3-a9ce-12e0fae63365',
 '02223264-e28a-4720-9f20-1e7a27a7041d',
 '62a74b85-0d4b-49f5-8794-74bafd871cd4',
 '3e331b72-51fd-4408-bc0d-b6c5ac3b9f3e',
 '4f7a4c3b-31e3-4023-8c9d-e67f627a34f0',
 'dac91856-cb6a-4f69-8c03-38ff0b29aab2',
 '8cb9045c-7266-4c40-9a76-65f3c5d5bb60',
 'decc6e78-a3db-4cd3-ad23-2bf8ed77cb0d',
 'c76d7899-d495-4103-9355-012c0a6fece3',
 'e22a9048-9a97-41b1-91a2-d4178c674b37',
 'f51dc5a7-37b7-4ce1-859a-b7cb58be6494',
 '764b812f-a0bb-4f4d-8e2f-c255c9474a0e']


batch = vows.describe("Bugdir interface").addBatch
  "":
    topic: () ->
        bs = new be.FileStorage('test/sampledata/.be')
        bd = new be.Bugdir bs
        bd.read (err, instance) =>
            this.callback(err, instance)
        return

    "test settings": (bdir) ->
        #console.log("bdir test", bdir)
        
        assert.equal(bdir.uuid, "bea86499-824e-4e77-b085-2d581fa9ccab")
        
        assert.deepEqual(bdir.inactive_status, [
              [ 'closed', 'The bug is no longer relevant.' ],
              [ 'fixed', 'The bug should no longer occur.' ],
              [ 'wontfix', "It's not a bug, it's a feature." ],
              [ 'disabled', 'Unknown meaning.  For backwards compatibility with old BE bugs.' ] ])
        assert.equal(bdir.active_status, null)
        assert.deepEqual(bdir.settings.extra_strings, [ "SUBSCRIBE:W. Trevor King <wking@drexel.edu>\tall\t*" ])

    "test bug uuids":
        topic: (bdir) ->
            callback = this.callback
            bdir.list_uuids (err, uuids) ->
                callback(err, uuids)
            return

        "test all keys": (err, uuids, bdir) ->
            test_uids = UIDS[0...UIDS.length]
            for uid in uuids
                idx = test_uids.indexOf(uid)
                assert.ok(idx > -1, "bug not found in static list: " + uid)
                test_uids.splice(idx, 1)
            assert.equal(test_uids.length, 0, "not all uuids found")

        "get bug":
            topic: (uuids, bdir) ->
                callback = this.callback
                all_bugs = []
                for uuid in uuids
                    bdir.bug_from_uuid uuid, (err, bug) ->
                        all_bugs.push(bug)
                        if all_bugs.length == UIDS.length
                            for b in all_bugs
                                callback(err, b)
                return

            "test bug values": (err, bug, uuids, bdir) ->
                assert.ok(bug.summary, "summary is empty")
                assert.ok(Object.keys(bug.values).length >= 3, "not enougth values" + Object.keys(bug.values).length)
                assert.ok(bug.creator)
                assert.ok(bug.time)

batch.export(module)

